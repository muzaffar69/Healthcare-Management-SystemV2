#!/usr/bin/env python3
"""
Medical Practice Management Admin Application

This is a Python-based admin application that manages doctor accounts
and their associated pharmacy and lab accounts in the Azure cloud.
"""

import os
import sys
import logging
import tkinter as tk
from tkinter import ttk, messagebox, simpledialog
import uuid
import json
import secrets
import string
import datetime
import threading
from typing import List, Dict, Any, Optional, Tuple

# Azure imports
import azure.identity
import azure.cosmos
import azure.storage.blob
import azure.core.exceptions
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.cosmosdb import CosmosDBManagementClient
from azure.mgmt.storage import StorageManagementClient
from azure.graphrbac import GraphRbacManagementClient
from azure.graphrbac.models import UserCreateParameters, PasswordProfile

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("admin_app.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class AzureServices:
    """Handles connections to Azure services and provides common operations."""
    
    def __init__(self, config: Dict[str, Any]) -> None:
        """Initialize Azure services with configuration."""
        self.config = config
        self.cosmos_client = None
        self.blob_service_client = None
        self.graph_client = None
        self.resource_client = None
        self.cosmosdb_client = None
        self.storage_client = None
        
        self._initialize_clients()
    
    def _initialize_clients(self) -> None:
        """Initialize all Azure clients."""
        try:
            # Azure AD credentials
            credential = azure.identity.ClientSecretCredential(
                tenant_id=self.config['azure_tenant_id'],
                client_id=self.config['azure_client_id'],
                client_secret=self.config['azure_client_secret']
            )
            
            # Initialize Cosmos DB client
            self.cosmos_client = azure.cosmos.CosmosClient(
                url=self.config['cosmos_endpoint'],
                credential=credential
            )
            
            # Initialize Blob Storage client
            self.blob_service_client = azure.storage.blob.BlobServiceClient(
                account_url=f"https://{self.config['storage_account_name']}.blob.core.windows.net",
                credential=credential
            )
            
            # Initialize Graph client for Azure AD operations
            self.graph_client = GraphRbacManagementClient(
                credentials=credential,
                tenant_id=self.config['azure_tenant_id']
            )
            
            # Initialize Azure Management clients
            subscription_id = self.config['subscription_id']
            self.resource_client = ResourceManagementClient(credential, subscription_id)
            self.cosmosdb_client = CosmosDBManagementClient(credential, subscription_id)
            self.storage_client = StorageManagementClient(credential, subscription_id)
            
            logger.info("Azure clients initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize Azure clients: {str(e)}")
            raise
    
    def create_doctor_account(self, doctor_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new doctor account in Azure AD and databases."""
        try:
            # Generate a secure random password
            password = self._generate_secure_password()
            
            # Create Azure AD account for the doctor
            user_principal_name = f"{doctor_data['email']}"
            display_name = f"{doctor_data['first_name']} {doctor_data['last_name']}"
            
            # Create password profile
            password_profile = PasswordProfile(
                password=password,
                force_change_password_next_login=True
            )
            
            # Create user parameters
            user_params = UserCreateParameters(
                user_principal_name=user_principal_name,
                account_enabled=True,
                display_name=display_name,
                mail_nickname=doctor_data['first_name'].lower(),
                password_profile=password_profile
            )
            
            # Create the user in Azure AD
            user = self.graph_client.users.create(user_params)
            
            # Generate unique IDs for associated accounts
            doctor_id = str(uuid.uuid4())
            pharmacy_id = str(uuid.uuid4())
            
            # Determine if lab account should be created
            lab_id = str(uuid.uuid4()) if doctor_data.get('create_lab_account', False) else None
            
            # Create doctor record in Cosmos DB
            doctor_record = {
                'id': doctor_id,
                'userId': user.object_id,
                'email': doctor_data['email'],
                'firstName': doctor_data['first_name'],
                'lastName': doctor_data['last_name'],
                'displayName': display_name,
                'role': 'doctor',
                'speciality': doctor_data.get('speciality', ''),
                'phoneNumber': doctor_data.get('phone_number', ''),
                'address': doctor_data.get('address', ''),
                'isActive': True,
                'hasPharmacyAccount': True,
                'hasLabAccount': lab_id is not None,
                'pharmacyAccountId': pharmacy_id,
                'labAccountId': lab_id,
                'pharmacyAccountActive': True,
                'labAccountActive': lab_id is not None,
                'subscriptionStartDate': datetime.datetime.now().isoformat(),
                'subscriptionEndDate': (datetime.datetime.now() + 
                                        datetime.timedelta(days=365)).isoformat(),
                'createdAt': datetime.datetime.now().isoformat(),
                'updatedAt': datetime.datetime.now().isoformat(),
                'settings': {}
            }
            
            # Create a database container for users if it doesn't exist
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Create doctor record
            users_container.create_item(body=doctor_record)
            
            # Create pharmacy account
            pharmacy_code = self._generate_access_code()
            pharmacy_record = {
                'id': pharmacy_id,
                'doctorId': doctor_id,
                'name': f"{display_name}'s Pharmacy",
                'email': f"pharmacy-{doctor_id[:8]}@example.com",
                'role': 'pharmacy',
                'accessCode': pharmacy_code,
                'isActive': True,
                'createdAt': datetime.datetime.now().isoformat(),
                'updatedAt': datetime.datetime.now().isoformat()
            }
            users_container.create_item(body=pharmacy_record)
            
            # Create lab account if requested
            lab_code = None
            if lab_id:
                lab_code = self._generate_access_code()
                lab_record = {
                    'id': lab_id,
                    'doctorId': doctor_id,
                    'name': f"{display_name}'s Laboratory",
                    'email': f"lab-{doctor_id[:8]}@example.com",
                    'role': 'laboratory',
                    'accessCode': lab_code,
                    'isActive': True,
                    'createdAt': datetime.datetime.now().isoformat(),
                    'updatedAt': datetime.datetime.now().isoformat()
                }
                users_container.create_item(body=lab_record)
            
            # Create container for the doctor's patients and other data
            patients_container_name = f"patients-{doctor_id}"
            database.create_container_if_not_exists(
                id=patients_container_name,
                partition_key=azure.cosmos.PartitionKey(path="/doctorId")
            )
            
            # Return the created accounts and access codes
            return {
                'doctor_id': doctor_id,
                'doctor_email': doctor_data['email'],
                'doctor_password': password,
                'pharmacy_id': pharmacy_id,
                'pharmacy_code': pharmacy_code,
                'lab_id': lab_id,
                'lab_code': lab_code
            }
        
        except Exception as e:
            logger.error(f"Failed to create doctor account: {str(e)}")
            raise
    
    def get_doctor_accounts(self) -> List[Dict[str, Any]]:
        """Get all doctor accounts."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Query for doctor accounts
            query = "SELECT * FROM c WHERE c.role = 'doctor'"
            doctors = list(users_container.query_items(query=query, enable_cross_partition_query=True))
            
            return doctors
        except Exception as e:
            logger.error(f"Failed to get doctor accounts: {str(e)}")
            raise
    
    def update_doctor_account(self, doctor_id: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update a doctor account."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Get the doctor record
            doctor_record = users_container.read_item(item=doctor_id, partition_key=doctor_id)
            
            # Update the fields
            for key, value in update_data.items():
                if key in doctor_record:
                    doctor_record[key] = value
            
            doctor_record['updatedAt'] = datetime.datetime.now().isoformat()
            
            # Save the updated record
            updated_record = users_container.replace_item(item=doctor_id, body=doctor_record)
            
            return updated_record
        except Exception as e:
            logger.error(f"Failed to update doctor account: {str(e)}")
            raise
    
    def activate_doctor_account(self, doctor_id: str, active: bool) -> Dict[str, Any]:
        """Activate or deactivate a doctor account."""
        return self.update_doctor_account(doctor_id, {'isActive': active})
    
    def activate_pharmacy_account(self, doctor_id: str, active: bool) -> Dict[str, Any]:
        """Activate or deactivate a pharmacy account associated with a doctor."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Get the doctor record
            doctor_record = users_container.read_item(item=doctor_id, partition_key=doctor_id)
            
            # Update the doctor record
            doctor_record['pharmacyAccountActive'] = active
            doctor_record['updatedAt'] = datetime.datetime.now().isoformat()
            
            # Save the updated doctor record
            updated_doctor = users_container.replace_item(item=doctor_id, body=doctor_record)
            
            # Update the pharmacy account if it exists
            if doctor_record.get('pharmacyAccountId'):
                pharmacy_id = doctor_record['pharmacyAccountId']
                try:
                    pharmacy_record = users_container.read_item(item=pharmacy_id, partition_key=pharmacy_id)
                    pharmacy_record['isActive'] = active
                    pharmacy_record['updatedAt'] = datetime.datetime.now().isoformat()
                    users_container.replace_item(item=pharmacy_id, body=pharmacy_record)
                except azure.core.exceptions.ResourceNotFoundError:
                    logger.warning(f"Pharmacy account {pharmacy_id} not found")
            
            return updated_doctor
        except Exception as e:
            logger.error(f"Failed to activate pharmacy account: {str(e)}")
            raise
    
    def activate_lab_account(self, doctor_id: str, active: bool) -> Dict[str, Any]:
        """Activate or deactivate a lab account associated with a doctor."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Get the doctor record
            doctor_record = users_container.read_item(item=doctor_id, partition_key=doctor_id)
            
            # Update the doctor record
            doctor_record['labAccountActive'] = active
            doctor_record['updatedAt'] = datetime.datetime.now().isoformat()
            
            # Save the updated doctor record
            updated_doctor = users_container.replace_item(item=doctor_id, body=doctor_record)
            
            # Update the lab account if it exists
            if doctor_record.get('labAccountId'):
                lab_id = doctor_record['labAccountId']
                try:
                    lab_record = users_container.read_item(item=lab_id, partition_key=lab_id)
                    lab_record['isActive'] = active
                    lab_record['updatedAt'] = datetime.datetime.now().isoformat()
                    users_container.replace_item(item=lab_id, body=lab_record)
                except azure.core.exceptions.ResourceNotFoundError:
                    logger.warning(f"Lab account {lab_id} not found")
            
            return updated_doctor
        except Exception as e:
            logger.error(f"Failed to activate lab account: {str(e)}")
            raise
    
    def add_lab_account_to_doctor(self, doctor_id: str) -> Dict[str, Any]:
        """Add a lab account to a doctor who doesn't have one."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Get the doctor record
            doctor_record = users_container.read_item(item=doctor_id, partition_key=doctor_id)
            
            # Check if the doctor already has a lab account
            if doctor_record.get('hasLabAccount', False) and doctor_record.get('labAccountId'):
                return doctor_record  # Doctor already has a lab account
            
            # Create a new lab account
            lab_id = str(uuid.uuid4())
            lab_code = self._generate_access_code()
            
            display_name = doctor_record.get('displayName', 'Doctor')
            
            lab_record = {
                'id': lab_id,
                'doctorId': doctor_id,
                'name': f"{display_name}'s Laboratory",
                'email': f"lab-{doctor_id[:8]}@example.com",
                'role': 'laboratory',
                'accessCode': lab_code,
                'isActive': True,
                'createdAt': datetime.datetime.now().isoformat(),
                'updatedAt': datetime.datetime.now().isoformat()
            }
            
            # Create the lab account
            users_container.create_item(body=lab_record)
            
            # Update the doctor record
            doctor_record['hasLabAccount'] = True
            doctor_record['labAccountId'] = lab_id
            doctor_record['labAccountActive'] = True
            doctor_record['updatedAt'] = datetime.datetime.now().isoformat()
            
            # Save the updated doctor record
            updated_doctor = users_container.replace_item(item=doctor_id, body=doctor_record)
            
            return {
                'doctor': updated_doctor,
                'lab_id': lab_id,
                'lab_code': lab_code
            }
        except Exception as e:
            logger.error(f"Failed to add lab account to doctor: {str(e)}")
            raise
    
    def regenerate_access_code(self, account_id: str) -> str:
        """Regenerate access code for a pharmacy or lab account."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Get the account record
            account_record = users_container.read_item(item=account_id, partition_key=account_id)
            
            # Check if this is a pharmacy or lab account
            if account_record.get('role') not in ['pharmacy', 'laboratory']:
                raise ValueError("Account is not a pharmacy or lab account")
            
            # Generate a new access code
            new_code = self._generate_access_code()
            
            # Update the account record
            account_record['accessCode'] = new_code
            account_record['updatedAt'] = datetime.datetime.now().isoformat()
            
            # Save the updated account record
            users_container.replace_item(item=account_id, body=account_record)
            
            return new_code
        except Exception as e:
            logger.error(f"Failed to regenerate access code: {str(e)}")
            raise
    
    def update_subscription(self, doctor_id: str, days: int) -> Dict[str, Any]:
        """Update a doctor's subscription by adding days to the end date."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Get the doctor record
            doctor_record = users_container.read_item(item=doctor_id, partition_key=doctor_id)
            
            # Calculate the new end date
            current_end_date = doctor_record.get('subscriptionEndDate')
            if current_end_date:
                current_end = datetime.datetime.fromisoformat(current_end_date.replace('Z', '+00:00'))
            else:
                current_end = datetime.datetime.now()
                
            new_end = current_end + datetime.timedelta(days=days)
            
            # Update the doctor record
            doctor_record['subscriptionEndDate'] = new_end.isoformat()
            doctor_record['updatedAt'] = datetime.datetime.now().isoformat()
            
            # Save the updated doctor record
            updated_doctor = users_container.replace_item(item=doctor_id, body=doctor_record)
            
            return updated_doctor
        except Exception as e:
            logger.error(f"Failed to update subscription: {str(e)}")
            raise
    
    def _generate_secure_password(self, length: int = 16) -> str:
        """Generate a secure random password."""
        alphabet = string.ascii_letters + string.digits + string.punctuation
        return ''.join(secrets.choice(alphabet) for _ in range(length))
    
    def _generate_access_code(self, length: int = 8) -> str:
        """Generate a pharmacy or lab access code."""
        alphabet = string.ascii_uppercase + string.digits
        return ''.join(secrets.choice(alphabet) for _ in range(length))


class AdminApp:
    """Medical Practice Admin Application."""
    
    def __init__(self, config_file: str = 'config.json') -> None:
        """Initialize the admin application."""
        self.config = self._load_config(config_file)
        self.azure = AzureServices(self.config)
        
        # Create the main window
        self.root = tk.Tk()
        self.root.title("Medical Practice Admin")
        self.root.geometry("1200x800")
        self.root.minsize(800, 600)
        
        # Set up the UI
        self._setup_ui()
    
    def _load_config(self, config_file: str) -> Dict[str, Any]:
        """Load configuration from a JSON file."""
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
            return config
        except FileNotFoundError:
            # Create a default config file if it doesn't exist
            default_config = {
                "azure_tenant_id": "",
                "azure_client_id": "",
                "azure_client_secret": "",
                "subscription_id": "",
                "cosmos_endpoint": "",
                "cosmos_key": "",
                "cosmos_database": "medical_practice",
                "cosmos_users_container": "users",
                "storage_account_name": "",
                "storage_account_key": ""
            }
            with open(config_file, 'w') as f:
                json.dump(default_config, f, indent=4)
            
            logger.warning(f"Config file not found. Created default config at {config_file}")
            return default_config
        except Exception as e:
            logger.error(f"Failed to load config: {str(e)}")
            raise
    
    def _setup_ui(self) -> None:
        """Set up the user interface."""
        # Create a notebook with tabs
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create frames for tabs
        self.doctors_frame = ttk.Frame(self.notebook)
        self.subscriptions_frame = ttk.Frame(self.notebook)
        self.settings_frame = ttk.Frame(self.notebook)
        
        # Add frames to notebook
        self.notebook.add(self.doctors_frame, text="Doctor Accounts")
        self.notebook.add(self.subscriptions_frame, text="Subscriptions")
        self.notebook.add(self.settings_frame, text="Settings")
        
        # Set up the doctors tab
        self._setup_doctors_tab()
        
        # Set up the subscriptions tab
        self._setup_subscriptions_tab()
        
        # Set up the settings tab
        self._setup_settings_tab()
        
        # Load the doctors list
        self._load_doctors()
    
    def _setup_doctors_tab(self) -> None:
        """Set up the doctors tab UI."""
        # Create a frame for the buttons
        button_frame = ttk.Frame(self.doctors_frame)
        button_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Add a refresh button
        refresh_button = ttk.Button(button_frame, text="Refresh", command=self._load_doctors)
        refresh_button.pack(side=tk.LEFT, padx=5)
        
        # Add a new doctor button
        new_doctor_button = ttk.Button(button_frame, text="New Doctor", command=self._show_new_doctor_dialog)
        new_doctor_button.pack(side=tk.LEFT, padx=5)
        
        # Create a frame for the treeview and scrollbar
        tree_frame = ttk.Frame(self.doctors_frame)
        tree_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create scrollbar
        scrollbar = ttk.Scrollbar(tree_frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Create the treeview
        self.doctors_tree = ttk.Treeview(
            tree_frame,
            columns=("id", "name", "email", "status", "pharmacy", "lab", "subscription"),
            show="headings",
            selectmode="browse",
            yscrollcommand=scrollbar.set
        )
        self.doctors_tree.pack(fill=tk.BOTH, expand=True)
        
        # Configure the scrollbar
        scrollbar.config(command=self.doctors_tree.yview)
        
        # Configure the treeview columns
        self.doctors_tree.heading("id", text="ID")
        self.doctors_tree.heading("name", text="Name")
        self.doctors_tree.heading("email", text="Email")
        self.doctors_tree.heading("status", text="Status")
        self.doctors_tree.heading("pharmacy", text="Pharmacy")
        self.doctors_tree.heading("lab", text="Laboratory")
        self.doctors_tree.heading("subscription", text="Subscription")
        
        self.doctors_tree.column("id", width=100)
        self.doctors_tree.column("name", width=200)
        self.doctors_tree.column("email", width=200)
        self.doctors_tree.column("status", width=100)
        self.doctors_tree.column("pharmacy", width=100)
        self.doctors_tree.column("lab", width=100)
        self.doctors_tree.column("subscription", width=200)
        
        # Bind double-click event
        self.doctors_tree.bind("<Double-1>", self._on_doctor_double_click)
        
        # Create a right-click menu
        self.doctor_menu = tk.Menu(self.root, tearoff=0)
        self.doctor_menu.add_command(label="Edit", command=self._edit_selected_doctor)
        self.doctor_menu.add_command(label="Activate/Deactivate", command=self._toggle_doctor_status)
        self.doctor_menu.add_command(label="Activate/Deactivate Pharmacy", command=self._toggle_pharmacy_status)
        self.doctor_menu.add_command(label="Activate/Deactivate Lab", command=self._toggle_lab_status)
        self.doctor_menu.add_command(label="Add Lab Account", command=self._add_lab_account)
        self.doctor_menu.add_command(label="Regenerate Pharmacy Code", command=self._regenerate_pharmacy_code)
        self.doctor_menu.add_command(label="Regenerate Lab Code", command=self._regenerate_lab_code)
        self.doctor_menu.add_separator()
        self.doctor_menu.add_command(label="View Details", command=self._view_doctor_details)
        
        # Bind right-click event
        self.doctors_tree.bind("<Button-3>", self._on_doctor_right_click)
    
    def _setup_subscriptions_tab(self) -> None:
        """Set up the subscriptions tab UI."""
        # Create a frame for the buttons
        button_frame = ttk.Frame(self.subscriptions_frame)
        button_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Add a refresh button
        refresh_button = ttk.Button(button_frame, text="Refresh", command=self._load_doctors)
        refresh_button.pack(side=tk.LEFT, padx=5)
        
        # Add a filter dropdown
        self.subscription_filter = tk.StringVar()
        self.subscription_filter.set("All")
        
        filter_label = ttk.Label(button_frame, text="Filter:")
        filter_label.pack(side=tk.LEFT, padx=5)
        
        filter_dropdown = ttk.Combobox(
            button_frame, 
            textvariable=self.subscription_filter,
            values=["All", "Active", "Expiring Soon", "Expired"]
        )
        filter_dropdown.pack(side=tk.LEFT, padx=5)
        filter_dropdown.bind("<<ComboboxSelected>>", self._filter_subscriptions)
        
        # Create a frame for the treeview and scrollbar
        tree_frame = ttk.Frame(self.subscriptions_frame)
        tree_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create scrollbar
        scrollbar = ttk.Scrollbar(tree_frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Create the treeview
        self.subscriptions_tree = ttk.Treeview(
            tree_frame,
            columns=("id", "name", "email", "start_date", "end_date", "days_left", "status"),
            show="headings",
            selectmode="browse",
            yscrollcommand=scrollbar.set
        )
        self.subscriptions_tree.pack(fill=tk.BOTH, expand=True)
        
        # Configure the scrollbar
        scrollbar.config(command=self.subscriptions_tree.yview)
        
        # Configure the treeview columns
        self.subscriptions_tree.heading("id", text="ID")
        self.subscriptions_tree.heading("name", text="Name")
        self.subscriptions_tree.heading("email", text="Email")
        self.subscriptions_tree.heading("start_date", text="Start Date")
        self.subscriptions_tree.heading("end_date", text="End Date")
        self.subscriptions_tree.heading("days_left", text="Days Left")
        self.subscriptions_tree.heading("status", text="Status")
        
        self.subscriptions_tree.column("id", width=100)
        self.subscriptions_tree.column("name", width=200)
        self.subscriptions_tree.column("email", width=200)
        self.subscriptions_tree.column("start_date", width=120)
        self.subscriptions_tree.column("end_date", width=120)
        self.subscriptions_tree.column("days_left", width=100)
        self.subscriptions_tree.column("status", width=100)
        
        # Bind double-click event
        self.subscriptions_tree.bind("<Double-1>", self._on_subscription_double_click)
        
        # Create a right-click menu
        self.subscription_menu = tk.Menu(self.root, tearoff=0)
        self.subscription_menu.add_command(label="Extend Subscription", command=self._extend_subscription)
        self.subscription_menu.add_separator()
        self.subscription_menu.add_command(label="View Doctor Details", command=self._view_doctor_details)
        
        # Bind right-click event
        self.subscriptions_tree.bind("<Button-3>", self._on_subscription_right_click)
    
    def _setup_settings_tab(self) -> None:
        """Set up the settings tab UI."""
        # Create a frame for the settings
        settings_frame = ttk.LabelFrame(self.settings_frame, text="Azure Configuration")
        settings_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create a container for the settings
        container = ttk.Frame(settings_frame)
        container.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create the settings fields
        row = 0
        
        # Azure AD settings
        ttk.Label(container, text="Azure AD Settings", font=("TkDefaultFont", 12, "bold")).grid(row=row, column=0, columnspan=2, sticky="w", pady=(0, 10))
        row += 1
        
        ttk.Label(container, text="Tenant ID:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.tenant_id_var = tk.StringVar(value=self.config.get("azure_tenant_id", ""))
        ttk.Entry(container, textvariable=self.tenant_id_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(container, text="Client ID:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.client_id_var = tk.StringVar(value=self.config.get("azure_client_id", ""))
        ttk.Entry(container, textvariable=self.client_id_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(container, text="Client Secret:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.client_secret_var = tk.StringVar(value=self.config.get("azure_client_secret", ""))
        ttk.Entry(container, textvariable=self.client_secret_var, width=50, show="*").grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(container, text="Subscription ID:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.subscription_id_var = tk.StringVar(value=self.config.get("subscription_id", ""))
        ttk.Entry(container, textvariable=self.subscription_id_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        # Add a separator
        ttk.Separator(container, orient="horizontal").grid(row=row, column=0, columnspan=2, sticky="ew", pady=10)
        row += 1
        
        # Cosmos DB settings
        ttk.Label(container, text="Cosmos DB Settings", font=("TkDefaultFont", 12, "bold")).grid(row=row, column=0, columnspan=2, sticky="w", pady=(0, 10))
        row += 1
        
        ttk.Label(container, text="Cosmos Endpoint:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.cosmos_endpoint_var = tk.StringVar(value=self.config.get("cosmos_endpoint", ""))
        ttk.Entry(container, textvariable=self.cosmos_endpoint_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(container, text="Cosmos Key:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.cosmos_key_var = tk.StringVar(value=self.config.get("cosmos_key", ""))
        ttk.Entry(container, textvariable=self.cosmos_key_var, width=50, show="*").grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(container, text="Database Name:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.cosmos_database_var = tk.StringVar(value=self.config.get("cosmos_database", "medical_practice"))
        ttk.Entry(container, textvariable=self.cosmos_database_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(container, text="Users Container:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.cosmos_users_container_var = tk.StringVar(value=self.config.get("cosmos_users_container", "users"))
        ttk.Entry(container, textvariable=self.cosmos_users_container_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        # Add a separator
        ttk.Separator(container, orient="horizontal").grid(row=row, column=0, columnspan=2, sticky="ew", pady=10)
        row += 1
        
        # Storage settings
        ttk.Label(container, text="Blob Storage Settings", font=("TkDefaultFont", 12, "bold")).grid(row=row, column=0, columnspan=2, sticky="w", pady=(0, 10))
        row += 1
        
        ttk.Label(container, text="Storage Account:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.storage_account_var = tk.StringVar(value=self.config.get("storage_account_name", ""))
        ttk.Entry(container, textvariable=self.storage_account_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(container, text="Storage Key:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.storage_key_var = tk.StringVar(value=self.config.get("storage_account_key", ""))
        ttk.Entry(container, textvariable=self.storage_key_var, width=50, show="*").grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        # Add save button
        button_frame = ttk.Frame(settings_frame)
        button_frame.pack(fill=tk.X, pady=10)
        
        save_button = ttk.Button(button_frame, text="Save Settings", command=self._save_settings)
        save_button.pack(side=tk.RIGHT, padx=10)
        
        test_button = ttk.Button(button_frame, text="Test Connection", command=self._test_connection)
        test_button.pack(side=tk.RIGHT, padx=10)
    
    def _load_doctors(self) -> None:
        """Load doctors from the database."""
        # Clear the treeviews
        self.doctors_tree.delete(*self.doctors_tree.get_children())
        self.subscriptions_tree.delete(*self.subscriptions_tree.get_children())
        
        try:
            # Start loading in a separate thread
            threading.Thread(target=self._load_doctors_thread).start()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load doctors: {str(e)}")
    
    def _load_doctors_thread(self) -> None:
        """Load doctors in a separate thread to avoid blocking the UI."""
        try:
            # Get doctors from Azure
            doctors = self.azure.get_doctor_accounts()
            
            # Sort doctors by name
            doctors.sort(key=lambda x: x.get('displayName', ''))
            
            # Update the UI in the main thread
            self.root.after(0, lambda: self._populate_doctor_trees(doctors))
        except Exception as e:
            # Show error message in the main thread
            self.root.after(0, lambda: messagebox.showerror("Error", f"Failed to load doctors: {str(e)}"))
    
    def _populate_doctor_trees(self, doctors: List[Dict[str, Any]]) -> None:
        """Populate the treeviews with doctor data."""
        # Clear the treeviews
        self.doctors_tree.delete(*self.doctors_tree.get_children())
        self.subscriptions_tree.delete(*self.subscriptions_tree.get_children())
        
        now = datetime.datetime.now()
        
        for doctor in doctors:
            # Get doctor data
            doctor_id = doctor.get('id', '')
            name = doctor.get('displayName', '')
            email = doctor.get('email', '')
            is_active = doctor.get('isActive', False)
            has_pharmacy = doctor.get('hasPharmacyAccount', False)
            pharmacy_active = doctor.get('pharmacyAccountActive', False)
            has_lab = doctor.get('hasLabAccount', False)
            lab_active = doctor.get('labAccountActive', False)
            
            # Get subscription data
            start_date_str = doctor.get('subscriptionStartDate', '')
            end_date_str = doctor.get('subscriptionEndDate', '')
            
            start_date = ""
            end_date = ""
            days_left = ""
            subscription_status = ""
            
            if start_date_str and end_date_str:
                try:
                    start_date_dt = datetime.datetime.fromisoformat(start_date_str.replace('Z', '+00:00'))
                    end_date_dt = datetime.datetime.fromisoformat(end_date_str.replace('Z', '+00:00'))
                    
                    start_date = start_date_dt.strftime("%Y-%m-%d")
                    end_date = end_date_dt.strftime("%Y-%m-%d")
                    
                    days_left = (end_date_dt - now).days
                    
                    if days_left < 0:
                        subscription_status = "Expired"
                    elif days_left < 30:
                        subscription_status = "Expiring Soon"
                    else:
                        subscription_status = "Active"
                except Exception as e:
                    logger.error(f"Failed to parse dates: {str(e)}")
            
            # Format the status strings
            status = "Active" if is_active else "Inactive"
            pharmacy = f"{'Yes' if has_pharmacy else 'No'} ({'Active' if pharmacy_active else 'Inactive'})"
            lab = f"{'Yes' if has_lab else 'No'} ({'Active' if lab_active else 'Inactive'})"
            subscription = f"{start_date} to {end_date} ({days_left} days left)"
            
            # Add to doctors treeview
            self.doctors_tree.insert(
                "",
                "end",
                values=(doctor_id, name, email, status, pharmacy, lab, subscription),
                tags=(doctor_id,)
            )
            
            # Add to subscriptions treeview
            self.subscriptions_tree.insert(
                "",
                "end",
                values=(doctor_id, name, email, start_date, end_date, days_left, subscription_status),
                tags=(doctor_id,)
            )
        
        # Apply subscription filter
        self._filter_subscriptions(None)
    
    def _filter_subscriptions(self, event) -> None:
        """Filter the subscriptions treeview based on the selected filter."""
        filter_value = self.subscription_filter.get()
        
        # Show all items
        for item in self.subscriptions_tree.get_children():
            self.subscriptions_tree.item(item, open=True)
        
        if filter_value == "All":
            return
        
        # Hide items that don't match the filter
        for item in self.subscriptions_tree.get_children():
            status = self.subscriptions_tree.item(item, "values")[6]
            
            if filter_value != status:
                self.subscriptions_tree.detach(item)
    
    def _on_doctor_double_click(self, event) -> None:
        """Handle double-click on a doctor in the treeview."""
        self._view_doctor_details()
    
    def _on_doctor_right_click(self, event) -> None:
        """Handle right-click on a doctor in the treeview."""
        # Select the item under the cursor
        iid = self.doctors_tree.identify_row(event.y)
        if iid:
            self.doctors_tree.selection_set(iid)
            self.doctor_menu.post(event.x_root, event.y_root)
    
    def _on_subscription_double_click(self, event) -> None:
        """Handle double-click on a subscription in the treeview."""
        self._extend_subscription()
    
    def _on_subscription_right_click(self, event) -> None:
        """Handle right-click on a subscription in the treeview."""
        # Select the item under the cursor
        iid = self.subscriptions_tree.identify_row(event.y)
        if iid:
            self.subscriptions_tree.selection_set(iid)
            self.subscription_menu.post(event.x_root, event.y_root)
    
    def _show_new_doctor_dialog(self) -> None:
        """Show a dialog to create a new doctor account."""
        # Create a top-level window
        dialog = tk.Toplevel(self.root)
        dialog.title("Create New Doctor")
        dialog.geometry("500x400")
        dialog.transient(self.root)
        dialog.grab_set()
        
        # Create a frame for the form
        form_frame = ttk.Frame(dialog, padding=10)
        form_frame.pack(fill=tk.BOTH, expand=True)
        
        # Create the form fields
        ttk.Label(form_frame, text="First Name:").grid(row=0, column=0, sticky="w", padx=5, pady=5)
        first_name_var = tk.StringVar()
        ttk.Entry(form_frame, textvariable=first_name_var, width=30).grid(row=0, column=1, sticky="ew", padx=5, pady=5)
        
        ttk.Label(form_frame, text="Last Name:").grid(row=1, column=0, sticky="w", padx=5, pady=5)
        last_name_var = tk.StringVar()
        ttk.Entry(form_frame, textvariable=last_name_var, width=30).grid(row=1, column=1, sticky="ew", padx=5, pady=5)
        
        ttk.Label(form_frame, text="Email:").grid(row=2, column=0, sticky="w", padx=5, pady=5)
        email_var = tk.StringVar()
        ttk.Entry(form_frame, textvariable=email_var, width=30).grid(row=2, column=1, sticky="ew", padx=5, pady=5)
        
        ttk.Label(form_frame, text="Specialty:").grid(row=3, column=0, sticky="w", padx=5, pady=5)
        specialty_var = tk.StringVar()
        ttk.Entry(form_frame, textvariable=specialty_var, width=30).grid(row=3, column=1, sticky="ew", padx=5, pady=5)
        
        ttk.Label(form_frame, text="Phone Number:").grid(row=4, column=0, sticky="w", padx=5, pady=5)
        phone_var = tk.StringVar()
        ttk.Entry(form_frame, textvariable=phone_var, width=30).grid(row=4, column=1, sticky="ew", padx=5, pady=5)
        
        ttk.Label(form_frame, text="Address:").grid(row=5, column=0, sticky="w", padx=5, pady=5)
        address_var = tk.StringVar()
        ttk.Entry(form_frame, textvariable=address_var, width=30).grid(row=5, column=1, sticky="ew", padx=5, pady=5)
        
        ttk.Label(form_frame, text="Create Lab Account:").grid(row=6, column=0, sticky="w", padx=5, pady=5)
        create_lab_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(form_frame, variable=create_lab_var).grid(row=6, column=1, sticky="w", padx=5, pady=5)
        
        # Create a text widget for the result
        result_frame = ttk.LabelFrame(dialog, text="Account Information", padding=10)
        result_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        result_text = tk.Text(result_frame, height=10, width=50, wrap=tk.WORD, state=tk.DISABLED)
        result_text.pack(fill=tk.BOTH, expand=True)
        
        # Create buttons
        button_frame = ttk.Frame(dialog, padding=10)
        button_frame.pack(fill=tk.X)
        
        create_button = ttk.Button(
            button_frame,
            text="Create",
            command=lambda: self._create_doctor(
                dialog,
                result_text,
                first_name_var.get(),
                last_name_var.get(),
                email_var.get(),
                specialty_var.get(),
                phone_var.get(),
                address_var.get(),
                create_lab_var.get()
            )
        )
        create_button.pack(side=tk.RIGHT, padx=5)
        
        cancel_button = ttk.Button(button_frame, text="Close", command=dialog.destroy)
        cancel_button.pack(side=tk.RIGHT, padx=5)
    
    def _create_doctor(
        self,
        dialog: tk.Toplevel,
        result_text: tk.Text,
        first_name: str,
        last_name: str,
        email: str,
        specialty: str,
        phone: str,
        address: str,
        create_lab: bool
    ) -> None:
        """Create a new doctor account."""
        # Validate the inputs
        if not first_name or not last_name or not email:
            messagebox.showerror("Error", "First name, last name, and email are required.")
            return
        
        try:
            # Create the doctor data
            doctor_data = {
                'first_name': first_name,
                'last_name': last_name,
                'email': email,
                'speciality': specialty,
                'phone_number': phone,
                'address': address,
                'create_lab_account': create_lab
            }
            
            # Create the doctor account
            result = self.azure.create_doctor_account(doctor_data)
            
            # Update the result text
            result_text.config(state=tk.NORMAL)
            result_text.delete(1.0, tk.END)
            
            result_text.insert(tk.END, "Doctor account created successfully!\n\n")
            result_text.insert(tk.END, f"Doctor ID: {result['doctor_id']}\n")
            result_text.insert(tk.END, f"Doctor Email: {result['doctor_email']}\n")
            result_text.insert(tk.END, f"Doctor Password: {result['doctor_password']}\n\n")
            result_text.insert(tk.END, f"Pharmacy ID: {result['pharmacy_id']}\n")
            result_text.insert(tk.END, f"Pharmacy Code: {result['pharmacy_code']}\n\n")
            
            if result['lab_id']:
                result_text.insert(tk.END, f"Lab ID: {result['lab_id']}\n")
                result_text.insert(tk.END, f"Lab Code: {result['lab_code']}\n")
            
            result_text.config(state=tk.DISABLED)
            
            # Reload the doctors list
            self._load_doctors()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to create doctor account: {str(e)}")
    
    def _edit_selected_doctor(self) -> None:
        """Edit the selected doctor account."""
        # Get the selected doctor
        selected = self.doctors_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select a doctor first.")
            return
        
        doctor_id = self.doctors_tree.item(selected[0], "values")[0]
        
        # Get the doctor data
        try:
            doctors = self.azure.get_doctor_accounts()
            doctor = next((d for d in doctors if d.get('id') == doctor_id), None)
            
            if not doctor:
                messagebox.showerror("Error", f"Doctor with ID {doctor_id} not found.")
                return
            
            # Create a top-level window
            dialog = tk.Toplevel(self.root)
            dialog.title("Edit Doctor")
            dialog.geometry("500x400")
            dialog.transient(self.root)
            dialog.grab_set()
            
            # Create a frame for the form
            form_frame = ttk.Frame(dialog, padding=10)
            form_frame.pack(fill=tk.BOTH, expand=True)
            
            # Create the form fields
            ttk.Label(form_frame, text="ID:").grid(row=0, column=0, sticky="w", padx=5, pady=5)
            id_var = tk.StringVar(value=doctor.get('id', ''))
            ttk.Entry(form_frame, textvariable=id_var, width=30, state="readonly").grid(row=0, column=1, sticky="ew", padx=5, pady=5)
            
            ttk.Label(form_frame, text="First Name:").grid(row=1, column=0, sticky="w", padx=5, pady=5)
            first_name_var = tk.StringVar(value=doctor.get('firstName', ''))
            ttk.Entry(form_frame, textvariable=first_name_var, width=30).grid(row=1, column=1, sticky="ew", padx=5, pady=5)
            
            ttk.Label(form_frame, text="Last Name:").grid(row=2, column=0, sticky="w", padx=5, pady=5)
            last_name_var = tk.StringVar(value=doctor.get('lastName', ''))
            ttk.Entry(form_frame, textvariable=last_name_var, width=30).grid(row=2, column=1, sticky="ew", padx=5, pady=5)
            
            ttk.Label(form_frame, text="Email:").grid(row=3, column=0, sticky="w", padx=5, pady=5)
            email_var = tk.StringVar(value=doctor.get('email', ''))
            ttk.Entry(form_frame, textvariable=email_var, width=30).grid(row=3, column=1, sticky="ew", padx=5, pady=5)
            
            ttk.Label(form_frame, text="Specialty:").grid(row=4, column=0, sticky="w", padx=5, pady=5)
            specialty_var = tk.StringVar(value=doctor.get('speciality', ''))
            ttk.Entry(form_frame, textvariable=specialty_var, width=30).grid(row=4, column=1, sticky="ew", padx=5, pady=5)
            
            ttk.Label(form_frame, text="Phone Number:").grid(row=5, column=0, sticky="w", padx=5, pady=5)
            phone_var = tk.StringVar(value=doctor.get('phoneNumber', ''))
            ttk.Entry(form_frame, textvariable=phone_var, width=30).grid(row=5, column=1, sticky="ew", padx=5, pady=5)
            
            ttk.Label(form_frame, text="Address:").grid(row=6, column=0, sticky="w", padx=5, pady=5)
            address_var = tk.StringVar(value=doctor.get('address', ''))
            ttk.Entry(form_frame, textvariable=address_var, width=30).grid(row=6, column=1, sticky="ew", padx=5, pady=5)
            
            ttk.Label(form_frame, text="Active:").grid(row=7, column=0, sticky="w", padx=5, pady=5)
            active_var = tk.BooleanVar(value=doctor.get('isActive', False))
            ttk.Checkbutton(form_frame, variable=active_var).grid(row=7, column=1, sticky="w", padx=5, pady=5)
            
            # Create buttons
            button_frame = ttk.Frame(dialog, padding=10)
            button_frame.pack(fill=tk.X)
            
            save_button = ttk.Button(
                button_frame,
                text="Save",
                command=lambda: self._update_doctor(
                    dialog,
                    doctor_id,
                    first_name_var.get(),
                    last_name_var.get(),
                    email_var.get(),
                    specialty_var.get(),
                    phone_var.get(),
                    address_var.get(),
                    active_var.get()
                )
            )
            save_button.pack(side=tk.RIGHT, padx=5)
            
            cancel_button = ttk.Button(button_frame, text="Cancel", command=dialog.destroy)
            cancel_button.pack(side=tk.RIGHT, padx=5)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to get doctor data: {str(e)}")
    
    def _update_doctor(
        self,
        dialog: tk.Toplevel,
        doctor_id: str,
        first_name: str,
        last_name: str,
        email: str,
        specialty: str,
        phone: str,
        address: str,
        active: bool
    ) -> None:
        """Update a doctor account."""
        # Validate the inputs
        if not first_name or not last_name or not email:
            messagebox.showerror("Error", "First name, last name, and email are required.")
            return
        
        try:
            # Create the update data
            update_data = {
                'firstName': first_name,
                'lastName': last_name,
                'email': email,
                'speciality': specialty,
                'phoneNumber': phone,
                'address': address,
                'isActive': active,
                'displayName': f"{first_name} {last_name}"
            }
            
            # Update the doctor account
            self.azure.update_doctor_account(doctor_id, update_data)
            
            # Close the dialog
            dialog.destroy()
            
            # Reload the doctors list
            self._load_doctors()
            
            messagebox.showinfo("Success", "Doctor account updated successfully.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to update doctor account: {str(e)}")
    
    def _toggle_doctor_status(self) -> None:
        """Toggle the active status of the selected doctor."""
        # Get the selected doctor
        selected = self.doctors_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select a doctor first.")
            return
        
        doctor_id = self.doctors_tree.item(selected[0], "values")[0]
        status = self.doctors_tree.item(selected[0], "values")[3]
        
        # Determine the new status
        new_status = status != "Active"
        
        try:
            # Update the doctor account
            self.azure.activate_doctor_account(doctor_id, new_status)
            
            # Reload the doctors list
            self._load_doctors()
            
            messagebox.showinfo("Success", f"Doctor account {'activated' if new_status else 'deactivated'} successfully.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to update doctor status: {str(e)}")
    
    def _toggle_pharmacy_status(self) -> None:
        """Toggle the active status of the pharmacy account associated with the selected doctor."""
        # Get the selected doctor
        selected = self.doctors_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select a doctor first.")
            return
        
        doctor_id = self.doctors_tree.item(selected[0], "values")[0]
        pharmacy = self.doctors_tree.item(selected[0], "values")[4]
        
        # Parse the pharmacy status
        if "Yes" not in pharmacy:
            messagebox.showinfo("Info", "This doctor does not have a pharmacy account.")
            return
        
        # Determine the new status
        new_status = "Inactive" in pharmacy
        
        try:
            # Update the pharmacy account
            self.azure.activate_pharmacy_account(doctor_id, new_status)
            
            # Reload the doctors list
            self._load_doctors()
            
            messagebox.showinfo("Success", f"Pharmacy account {'activated' if new_status else 'deactivated'} successfully.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to update pharmacy status: {str(e)}")
    
    def _toggle_lab_status(self) -> None:
        """Toggle the active status of the lab account associated with the selected doctor."""
        # Get the selected doctor
        selected = self.doctors_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select a doctor first.")
            return
        
        doctor_id = self.doctors_tree.item(selected[0], "values")[0]
        lab = self.doctors_tree.item(selected[0], "values")[5]
        
        # Parse the lab status
        if "Yes" not in lab:
            messagebox.showinfo("Info", "This doctor does not have a lab account.")
            return
        
        # Determine the new status
        new_status = "Inactive" in lab
        
        try:
            # Update the lab account
            self.azure.activate_lab_account(doctor_id, new_status)
            
            # Reload the doctors list
            self._load_doctors()
            
            messagebox.showinfo("Success", f"Lab account {'activated' if new_status else 'deactivated'} successfully.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to update lab status: {str(e)}")
    
    def _add_lab_account(self) -> None:
        """Add a lab account to the selected doctor."""
        # Get the selected doctor
        selected = self.doctors_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select a doctor first.")
            return
        
        doctor_id = self.doctors_tree.item(selected[0], "values")[0]
        lab = self.doctors_tree.item(selected[0], "values")[5]
        
        # Check if the doctor already has a lab account
        if "Yes" in lab:
            messagebox.showinfo("Info", "This doctor already has a lab account.")
            return
        
        try:
            # Add a lab account
            result = self.azure.add_lab_account_to_doctor(doctor_id)
            
            # Reload the doctors list
            self._load_doctors()
            
            # Show a success message with the lab code
            messagebox.showinfo(
                "Success",
                f"Lab account added successfully.\n\nLab ID: {result['lab_id']}\nLab Code: {result['lab_code']}"
            )
        except Exception as e:
            messagebox.showerror("Error", f"Failed to add lab account: {str(e)}")
    
    def _regenerate_pharmacy_code(self) -> None:
        """Regenerate the access code for the pharmacy account associated with the selected doctor."""
        # Get the selected doctor
        selected = self.doctors_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select a doctor first.")
            return
        
        doctor_id = self.doctors_tree.item(selected[0], "values")[0]
        pharmacy = self.doctors_tree.item(selected[0], "values")[4]
        
        # Parse the pharmacy status
        if "Yes" not in pharmacy:
            messagebox.showinfo("Info", "This doctor does not have a pharmacy account.")
            return
        
        try:
            # Get the doctor data
            doctors = self.azure.get_doctor_accounts()
            doctor = next((d for d in doctors if d.get('id') == doctor_id), None)
            
            if not doctor:
                messagebox.showerror("Error", f"Doctor with ID {doctor_id} not found.")
                return
            
            # Get the pharmacy ID
            pharmacy_id = doctor.get('pharmacyAccountId')
            if not pharmacy_id:
                messagebox.showerror("Error", "Pharmacy account ID not found.")
                return
            
            # Regenerate the access code
            new_code = self.azure.regenerate_access_code(pharmacy_id)
            
            # Show a success message with the new code
            messagebox.showinfo(
                "Success",
                f"Pharmacy access code regenerated successfully.\n\nNew Code: {new_code}"
            )
        except Exception as e:
            messagebox.showerror("Error", f"Failed to regenerate pharmacy code: {str(e)}")
    
    def _regenerate_lab_code(self) -> None:
        """Regenerate the access code for the lab account associated with the selected doctor."""
        # Get the selected doctor
        selected = self.doctors_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select a doctor first.")
            return
        
        doctor_id = self.doctors_tree.item(selected[0], "values")[0]
        lab = self.doctors_tree.item(selected[0], "values")[5]
        
        # Parse the lab status
        if "Yes" not in lab:
            messagebox.showinfo("Info", "This doctor does not have a lab account.")
            return
        
        try:
            # Get the doctor data
            doctors = self.azure.get_doctor_accounts()
            doctor = next((d for d in doctors if d.get('id') == doctor_id), None)
            
            if not doctor:
                messagebox.showerror("Error", f"Doctor with ID {doctor_id} not found.")
                return
            
            # Get the lab ID
            lab_id = doctor.get('labAccountId')
            if not lab_id:
                messagebox.showerror("Error", "Lab account ID not found.")
                return
            
            # Regenerate the access code
            new_code = self.azure.regenerate_access_code(lab_id)
            
            # Show a success message with the new code
            messagebox.showinfo(
                "Success",
                f"Lab access code regenerated successfully.\n\nNew Code: {new_code}"
            )
        except Exception as e:
            messagebox.showerror("Error", f"Failed to regenerate lab code: {str(e)}")
    
    def _view_doctor_details(self) -> None:
        """View the details of the selected doctor."""
        # Get the selected doctor
        selected = self.doctors_tree.selection() or self.subscriptions_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select a doctor first.")
            return
        
        doctor_id = self.doctors_tree.item(selected[0], "values")[0] if selected[0] in self.doctors_tree.get_children() else self.subscriptions_tree.item(selected[0], "values")[0]
        
        try:
            # Get the doctor data
            doctors = self.azure.get_doctor_accounts()
            doctor = next((d for d in doctors if d.get('id') == doctor_id), None)
            
            if not doctor:
                messagebox.showerror("Error", f"Doctor with ID {doctor_id} not found.")
                return
            
            # Create a top-level window
            dialog = tk.Toplevel(self.root)
            dialog.title("Doctor Details")
            dialog.geometry("600x500")
            dialog.transient(self.root)
            dialog.grab_set()
            
            # Create a text widget for the details
            text = tk.Text(dialog, wrap=tk.WORD, padx=10, pady=10)
            text.pack(fill=tk.BOTH, expand=True)
            
            # Insert the doctor details
            text.insert(tk.END, f"Doctor ID: {doctor.get('id', '')}\n\n")
            text.insert(tk.END, f"Name: {doctor.get('displayName', '')}\n")
            text.insert(tk.END, f"Email: {doctor.get('email', '')}\n")
            text.insert(tk.END, f"Specialty: {doctor.get('speciality', '')}\n")
            text.insert(tk.END, f"Phone: {doctor.get('phoneNumber', '')}\n")
            text.insert(tk.END, f"Address: {doctor.get('address', '')}\n\n")
            
            text.insert(tk.END, f"Active: {doctor.get('isActive', False)}\n\n")
            
            # Subscription details
            text.insert(tk.END, "Subscription:\n")
            start_date = doctor.get('subscriptionStartDate', '')
            end_date = doctor.get('subscriptionEndDate', '')
            
            if start_date and end_date:
                try:
                    start_date_dt = datetime.datetime.fromisoformat(start_date.replace('Z', '+00:00'))
                    end_date_dt = datetime.datetime.fromisoformat(end_date.replace('Z', '+00:00'))
                    
                    start_date_str = start_date_dt.strftime("%Y-%m-%d")
                    end_date_str = end_date_dt.strftime("%Y-%m-%d")
                    
                    days_left = (end_date_dt - datetime.datetime.now()).days
                    
                    text.insert(tk.END, f"Start Date: {start_date_str}\n")
                    text.insert(tk.END, f"End Date: {end_date_str}\n")
                    text.insert(tk.END, f"Days Left: {days_left}\n\n")
                except Exception as e:
                    logger.error(f"Failed to parse dates: {str(e)}")
                    text.insert(tk.END, f"Start Date: {start_date}\n")
                    text.insert(tk.END, f"End Date: {end_date}\n\n")
            
            # Pharmacy account details
            text.insert(tk.END, "Pharmacy Account:\n")
            text.insert(tk.END, f"Has Pharmacy Account: {doctor.get('hasPharmacyAccount', False)}\n")
            text.insert(tk.END, f"Pharmacy Account Active: {doctor.get('pharmacyAccountActive', False)}\n")
            text.insert(tk.END, f"Pharmacy Account ID: {doctor.get('pharmacyAccountId', '')}\n\n")
            
            # Lab account details
            text.insert(tk.END, "Lab Account:\n")
            text.insert(tk.END, f"Has Lab Account: {doctor.get('hasLabAccount', False)}\n")
            text.insert(tk.END, f"Lab Account Active: {doctor.get('labAccountActive', False)}\n")
            text.insert(tk.END, f"Lab Account ID: {doctor.get('labAccountId', '')}\n\n")
            
            # User ID and created/updated dates
            text.insert(tk.END, "System Information:\n")
            text.insert(tk.END, f"User ID: {doctor.get('userId', '')}\n")
            text.insert(tk.END, f"Created At: {doctor.get('createdAt', '')}\n")
            text.insert(tk.END, f"Updated At: {doctor.get('updatedAt', '')}\n")
            
            # Make the text widget read-only
            text.config(state=tk.DISABLED)
            
            # Add a close button
            close_button = ttk.Button(dialog, text="Close", command=dialog.destroy)
            close_button.pack(pady=10)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to get doctor details: {str(e)}")
    
    def _extend_subscription(self) -> None:
        """Extend the subscription of the selected doctor."""
        # Get the selected doctor
        selected = self.subscriptions_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select a doctor first.")
            return
        
        doctor_id = self.subscriptions_tree.item(selected[0], "values")[0]
        
        # Ask for the number of days to extend
        days = simpledialog.askinteger(
            "Extend Subscription",
            "Enter the number of days to extend the subscription:",
            parent=self.root,
            minvalue=1
        )
        
        if not days:
            return
        
        try:
            # Update the subscription
            self.azure.update_subscription(doctor_id, days)
            
            # Reload the doctors list
            self._load_doctors()
            
            messagebox.showinfo("Success", f"Subscription extended by {days} days successfully.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to extend subscription: {str(e)}")
    
    def _save_settings(self) -> None:
        """Save the settings to the config file."""
        try:
            # Update the config
            self.config.update({
                "azure_tenant_id": self.tenant_id_var.get(),
                "azure_client_id": self.client_id_var.get(),
                "azure_client_secret": self.client_secret_var.get(),
                "subscription_id": self.subscription_id_var.get(),
                "cosmos_endpoint": self.cosmos_endpoint_var.get(),
                "cosmos_key": self.cosmos_key_var.get(),
                "cosmos_database": self.cosmos_database_var.get(),
                "cosmos_users_container": self.cosmos_users_container_var.get(),
                "storage_account_name": self.storage_account_var.get(),
                "storage_account_key": self.storage_key_var.get()
            })
            
            # Save the config to file
            with open('config.json', 'w') as f:
                json.dump(self.config, f, indent=4)
            
            # Reinitialize the Azure services
            self.azure = AzureServices(self.config)
            
            messagebox.showinfo("Success", "Settings saved successfully.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to save settings: {str(e)}")
    
    def _test_connection(self) -> None:
        """Test the connection to Azure services."""
        try:
            # Save the settings first
            self._save_settings()
            
            # Try to get the doctors list
            self.azure.get_doctor_accounts()
            
            messagebox.showinfo("Success", "Connection test successful.")
        except Exception as e:
            messagebox.showerror("Error", f"Connection test failed: {str(e)}")
    
    def run(self) -> None:
        """Run the application."""
        self.root.mainloop()


if __name__ == "__main__":
    app = AdminApp()
    app.run()
