#!/usr/bin/env python3
"""
Medical Practice Management Owner Control Program

This is a Python-based owner control application with the highest system privileges
for managing the entire Medical Practice Management system in the Azure cloud.
"""

import os
import sys
import logging
import tkinter as tk
from tkinter import ttk, messagebox, simpledialog, filedialog
import uuid
import json
import secrets
import string
import datetime
import threading
import hashlib
import base64
import csv
from typing import List, Dict, Any, Optional, Tuple, Set

# Azure imports
import azure.identity
import azure.cosmos
import azure.storage.blob
import azure.core.exceptions
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.cosmosdb import CosmosDBManagementClient
from azure.mgmt.storage import StorageManagementClient
from azure.graphrbac import GraphRbacManagementClient
from azure.graphrbac.models import UserCreateParameters, PasswordProfile, UserUpdateParameters

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("owner_app.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class SecurityManager:
    """Handles security operations for the owner app."""
    
    @staticmethod
    def hash_password(password: str) -> str:
        """Hash a password using a secure method."""
        salt = os.urandom(32)
        key = hashlib.pbkdf2_hmac(
            'sha256',
            password.encode('utf-8'),
            salt,
            100000
        )
        return base64.b64encode(salt + key).decode('utf-8')
    
    @staticmethod
    def verify_password(stored_password: str, provided_password: str) -> bool:
        """Verify a password against its hash."""
        try:
            decoded = base64.b64decode(stored_password)
            salt = decoded[:32]
            stored_key = decoded[32:]
            new_key = hashlib.pbkdf2_hmac(
                'sha256',
                provided_password.encode('utf-8'),
                salt,
                100000
            )
            return stored_key == new_key
        except Exception as e:
            logger.error(f"Password verification error: {str(e)}")
            return False
    
    @staticmethod
    def generate_secure_password(length: int = 16) -> str:
        """Generate a secure random password."""
        alphabet = string.ascii_letters + string.digits + string.punctuation
        return ''.join(secrets.choice(alphabet) for _ in range(length))
    
    @staticmethod
    def generate_access_code(length: int = 8) -> str:
        """Generate an access code."""
        alphabet = string.ascii_uppercase + string.digits
        return ''.join(secrets.choice(alphabet) for _ in range(length))


class AzureServices:
    """Handles connections to Azure services and provides high-privilege operations."""
    
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
    
    def create_admin_account(self, admin_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new admin account in Azure AD and databases."""
        try:
            # Generate a secure random password
            password = SecurityManager.generate_secure_password()
            
            # Create Azure AD account for the admin
            user_principal_name = f"{admin_data['email']}"
            display_name = f"{admin_data['first_name']} {admin_data['last_name']}"
            
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
                mail_nickname=admin_data['first_name'].lower(),
                password_profile=password_profile
            )
            
            # Create the user in Azure AD
            user = self.graph_client.users.create(user_params)
            
            # Generate unique ID for admin account
            admin_id = str(uuid.uuid4())
            
            # Create admin record in Cosmos DB
            admin_record = {
                'id': admin_id,
                'userId': user.object_id,
                'email': admin_data['email'],
                'firstName': admin_data['first_name'],
                'lastName': admin_data['last_name'],
                'displayName': display_name,
                'role': 'admin',
                'isActive': True,
                'permissions': admin_data.get('permissions', {
                    'manageAccounts': True,
                    'viewReports': True,
                    'manageSettings': True
                }),
                'createdAt': datetime.datetime.now().isoformat(),
                'updatedAt': datetime.datetime.now().isoformat(),
            }
            
            # Create a database container for users if it doesn't exist
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Create admin record
            users_container.create_item(body=admin_record)
            
            # Return the created account
            return {
                'admin_id': admin_id,
                'admin_email': admin_data['email'],
                'admin_password': password,
            }
        
        except Exception as e:
            logger.error(f"Failed to create admin account: {str(e)}")
            raise
    
    def get_admin_accounts(self) -> List[Dict[str, Any]]:
        """Get all admin accounts."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Query for admin accounts
            query = "SELECT * FROM c WHERE c.role = 'admin'"
            admins = list(users_container.query_items(query=query, enable_cross_partition_query=True))
            
            return admins
        except Exception as e:
            logger.error(f"Failed to get admin accounts: {str(e)}")
            raise
    
    def update_admin_account(self, admin_id: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update an admin account."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Get the admin record
            admin_record = users_container.read_item(item=admin_id, partition_key=admin_id)
            
            # Make sure this is an admin account
            if admin_record.get('role') != 'admin':
                raise ValueError("The account is not an admin account")
            
            # Update the fields
            for key, value in update_data.items():
                if key in admin_record:
                    admin_record[key] = value
            
            admin_record['updatedAt'] = datetime.datetime.now().isoformat()
            
            # Save the updated record
            updated_record = users_container.replace_item(item=admin_id, body=admin_record)
            
            # If needed, update Azure AD user as well
            if 'firstName' in update_data or 'lastName' in update_data or 'email' in update_data:
                display_name = f"{admin_record['firstName']} {admin_record['lastName']}"
                
                # Update Azure AD user
                user_params = UserUpdateParameters(
                    display_name=display_name,
                    mail_nickname=admin_record['firstName'].lower(),
                )
                
                if 'email' in update_data:
                    user_principal_name = admin_record['email']
                    user_params.user_principal_name = user_principal_name
                
                self.graph_client.users.update(admin_record['userId'], user_params)
            
            return updated_record
        except Exception as e:
            logger.error(f"Failed to update admin account: {str(e)}")
            raise
    
    def delete_admin_account(self, admin_id: str) -> bool:
        """Delete an admin account."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Get the admin record
            admin_record = users_container.read_item(item=admin_id, partition_key=admin_id)
            
            # Make sure this is an admin account
            if admin_record.get('role') != 'admin':
                raise ValueError("The account is not an admin account")
            
            # Delete the admin record
            users_container.delete_item(item=admin_id, partition_key=admin_id)
            
            # Delete Azure AD user
            self.graph_client.users.delete(admin_record['userId'])
            
            return True
        except Exception as e:
            logger.error(f"Failed to delete admin account: {str(e)}")
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
    
    def deactivate_all_accounts_for_doctor(self, doctor_id: str) -> bool:
        """Deactivate a doctor account and all associated accounts."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Get the doctor record
            doctor_record = users_container.read_item(item=doctor_id, partition_key=doctor_id)
            
            # Update doctor record
            doctor_record['isActive'] = False
            doctor_record['updatedAt'] = datetime.datetime.now().isoformat()
            users_container.replace_item(item=doctor_id, body=doctor_record)
            
            # Update pharmacy account if it exists
            if doctor_record.get('pharmacyAccountId'):
                pharmacy_id = doctor_record['pharmacyAccountId']
                try:
                    pharmacy_record = users_container.read_item(item=pharmacy_id, partition_key=pharmacy_id)
                    pharmacy_record['isActive'] = False
                    pharmacy_record['updatedAt'] = datetime.datetime.now().isoformat()
                    users_container.replace_item(item=pharmacy_id, body=pharmacy_record)
                except azure.core.exceptions.ResourceNotFoundError:
                    logger.warning(f"Pharmacy account {pharmacy_id} not found")
            
            # Update lab account if it exists
            if doctor_record.get('labAccountId'):
                lab_id = doctor_record['labAccountId']
                try:
                    lab_record = users_container.read_item(item=lab_id, partition_key=lab_id)
                    lab_record['isActive'] = False
                    lab_record['updatedAt'] = datetime.datetime.now().isoformat()
                    users_container.replace_item(item=lab_id, body=lab_record)
                except azure.core.exceptions.ResourceNotFoundError:
                    logger.warning(f"Lab account {lab_id} not found")
            
            return True
        except Exception as e:
            logger.error(f"Failed to deactivate accounts: {str(e)}")
            raise
    
    def reset_password(self, user_id: str) -> str:
        """Reset the password for a user in Azure AD."""
        try:
            # Get the user record from Cosmos DB
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            user_record = users_container.read_item(item=user_id, partition_key=user_id)
            
            # Generate a new password
            new_password = SecurityManager.generate_secure_password()
            
            # Create password profile
            password_profile = PasswordProfile(
                password=new_password,
                force_change_password_next_login=True
            )
            
            # Update the user in Azure AD
            user_params = UserUpdateParameters(
                password_profile=password_profile
            )
            
            self.graph_client.users.update(user_record['userId'], user_params)
            
            return new_password
        except Exception as e:
            logger.error(f"Failed to reset password: {str(e)}")
            raise
    
    def export_data(self, collection_name: str, output_format: str) -> str:
        """Export data from a Cosmos DB collection to CSV or JSON."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            container = database.get_container_client(collection_name)
            
            # Query all documents
            items = list(container.query_items(
                query="SELECT * FROM c",
                enable_cross_partition_query=True
            ))
            
            # Create temp directory if it doesn't exist
            os.makedirs("exports", exist_ok=True)
            
            # Generate output filename
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"exports/{collection_name}_{timestamp}.{output_format}"
            
            if output_format.lower() == "json":
                # Export as JSON
                with open(filename, "w") as f:
                    json.dump(items, f, indent=2)
            
            elif output_format.lower() == "csv":
                # Export as CSV
                if not items:
                    # If no items, create empty file
                    with open(filename, "w") as f:
                        f.write("No data found")
                    return filename
                
                # Get all possible columns
                columns = set()
                for item in items:
                    columns.update(item.keys())
                
                # Sort columns for consistency, with 'id' first
                if 'id' in columns:
                    columns.remove('id')
                sorted_columns = ['id'] + sorted(columns)
                
                # Write to CSV
                with open(filename, "w", newline='') as f:
                    writer = csv.DictWriter(f, fieldnames=sorted_columns)
                    writer.writeheader()
                    for item in items:
                        # Ensure consistent column order
                        row = {col: item.get(col, '') for col in sorted_columns}
                        writer.writerow(row)
            
            else:
                raise ValueError(f"Unsupported format: {output_format}")
            
            return filename
        except Exception as e:
            logger.error(f"Failed to export data: {str(e)}")
            raise
    
    def backup_database(self) -> str:
        """Create a full backup of the Cosmos DB database."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            
            # Get all containers
            containers = list(database.list_containers())
            
            # Create backup directory
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_dir = f"backups/backup_{timestamp}"
            os.makedirs(backup_dir, exist_ok=True)
            
            # Export each container
            for container_info in containers:
                container_name = container_info['id']
                container = database.get_container_client(container_name)
                
                # Query all documents
                items = list(container.query_items(
                    query="SELECT * FROM c",
                    enable_cross_partition_query=True
                ))
                
                # Export as JSON
                filename = f"{backup_dir}/{container_name}.json"
                with open(filename, "w") as f:
                    json.dump(items, f, indent=2)
            
            # Create a manifest file
            manifest = {
                'timestamp': timestamp,
                'database': self.config['cosmos_database'],
                'containers': [c['id'] for c in containers],
                'total_containers': len(containers)
            }
            
            with open(f"{backup_dir}/manifest.json", "w") as f:
                json.dump(manifest, f, indent=2)
            
            # Create a ZIP archive
            import shutil
            backup_zip = f"backups/backup_{timestamp}.zip"
            shutil.make_archive(f"backups/backup_{timestamp}", 'zip', backup_dir)
            
            # Clean up the temporary directory
            shutil.rmtree(backup_dir)
            
            return backup_zip
        except Exception as e:
            logger.error(f"Failed to backup database: {str(e)}")
            raise
    
    def restore_database(self, backup_file: str) -> bool:
        """Restore a Cosmos DB database from backup."""
        try:
            import zipfile
            import tempfile
            
            # Create a temporary directory
            with tempfile.TemporaryDirectory() as temp_dir:
                # Extract the ZIP archive
                with zipfile.ZipFile(backup_file, 'r') as zip_ref:
                    zip_ref.extractall(temp_dir)
                
                # Read the manifest
                with open(f"{temp_dir}/manifest.json", "r") as f:
                    manifest = json.load(f)
                
                database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
                
                # Restore each container
                for container_name in manifest['containers']:
                    # Read the backup data
                    with open(f"{temp_dir}/{container_name}.json", "r") as f:
                        items = json.load(f)
                    
                    # Ensure the container exists
                    try:
                        container = database.get_container_client(container_name)
                    except azure.core.exceptions.ResourceNotFoundError:
                        # Create the container if it doesn't exist
                        database.create_container(
                            id=container_name,
                            partition_key=azure.cosmos.PartitionKey(path="/id")
                        )
                        container = database.get_container_client(container_name)
                    
                    # Restore each item
                    for item in items:
                        try:
                            # Try to read the item to see if it exists
                            container.read_item(item=item['id'], partition_key=item['id'])
                            
                            # If it exists, replace it
                            container.replace_item(item=item['id'], body=item)
                        except azure.core.exceptions.ResourceNotFoundError:
                            # If it doesn't exist, create it
                            container.create_item(body=item)
            
            return True
        except Exception as e:
            logger.error(f"Failed to restore database: {str(e)}")
            raise
    
    def get_system_metrics(self) -> Dict[str, Any]:
        """Get system-wide metrics for the medical practice management system."""
        try:
            database = self.cosmos_client.get_database_client(self.config['cosmos_database'])
            users_container = database.get_container_client(self.config['cosmos_users_container'])
            
            # Count active doctors
            query_doctors = "SELECT VALUE COUNT(1) FROM c WHERE c.role = 'doctor' AND c.isActive = true"
            active_doctors_count = list(users_container.query_items(
                query=query_doctors,
                enable_cross_partition_query=True
            ))[0]
            
            # Count inactive doctors
            query_inactive_doctors = "SELECT VALUE COUNT(1) FROM c WHERE c.role = 'doctor' AND c.isActive = false"
            inactive_doctors_count = list(users_container.query_items(
                query=query_inactive_doctors,
                enable_cross_partition_query=True
            ))[0]
            
            # Count admins
            query_admins = "SELECT VALUE COUNT(1) FROM c WHERE c.role = 'admin'"
            admins_count = list(users_container.query_items(
                query=query_admins,
                enable_cross_partition_query=True
            ))[0]
            
            # Count pharmacies
            query_pharmacies = "SELECT VALUE COUNT(1) FROM c WHERE c.role = 'pharmacy'"
            pharmacies_count = list(users_container.query_items(
                query=query_pharmacies,
                enable_cross_partition_query=True
            ))[0]
            
            # Count labs
            query_labs = "SELECT VALUE COUNT(1) FROM c WHERE c.role = 'laboratory'"
            labs_count = list(users_container.query_items(
                query=query_labs,
                enable_cross_partition_query=True
            ))[0]
            
            # Get list of containers to count patients, visits, etc.
            containers = list(database.list_containers())
            
            # Initialize counters
            total_patients = 0
            total_visits = 0
            total_prescriptions = 0
            total_lab_tests = 0
            
            # Count patient-related data
            for container_info in containers:
                container_name = container_info['id']
                
                # Skip the users container
                if container_name == self.config['cosmos_users_container']:
                    continue
                
                # Check if this is a patients container
                if container_name.startswith('patients-'):
                    container = database.get_container_client(container_name)
                    
                    # Count patients
                    query_patients = "SELECT VALUE COUNT(1) FROM c WHERE c.type = 'patient' AND c.isDeleted = false"
                    try:
                        patients_count = list(container.query_items(
                            query=query_patients,
                            enable_cross_partition_query=True
                        ))[0]
                        total_patients += patients_count
                    except:
                        # Skip if the query fails (e.g., if the container doesn't have the expected schema)
                        pass
                    
                    # Count visits
                    query_visits = "SELECT VALUE COUNT(1) FROM c WHERE c.type = 'visit' AND c.isDeleted = false"
                    try:
                        visits_count = list(container.query_items(
                            query=query_visits,
                            enable_cross_partition_query=True
                        ))[0]
                        total_visits += visits_count
                    except:
                        pass
                    
                    # Count prescriptions
                    query_prescriptions = "SELECT VALUE COUNT(1) FROM c WHERE c.type = 'prescription' AND c.isDeleted = false"
                    try:
                        prescriptions_count = list(container.query_items(
                            query=query_prescriptions,
                            enable_cross_partition_query=True
                        ))[0]
                        total_prescriptions += prescriptions_count
                    except:
                        pass
                    
                    # Count lab tests
                    query_lab_tests = "SELECT VALUE COUNT(1) FROM c WHERE c.type = 'labTest' AND c.isDeleted = false"
                    try:
                        lab_tests_count = list(container.query_items(
                            query=query_lab_tests,
                            enable_cross_partition_query=True
                        ))[0]
                        total_lab_tests += lab_tests_count
                    except:
                        pass
            
            # Get Azure resource usage
            # (This is just a placeholder - actual implementation would require more complex Azure SDK calls)
            storage_usage = {
                'total_gb': 10,
                'used_gb': 2.5,
                'percent_used': 25
            }
            
            database_usage = {
                'ru_provisioned': 400,
                'ru_consumed': 120,
                'percent_used': 30
            }
            
            # Return metrics
            return {
                'accounts': {
                    'doctors': {
                        'active': active_doctors_count,
                        'inactive': inactive_doctors_count,
                        'total': active_doctors_count + inactive_doctors_count
                    },
                    'admins': admins_count,
                    'pharmacies': pharmacies_count,
                    'labs': labs_count
                },
                'data': {
                    'patients': total_patients,
                    'visits': total_visits,
                    'prescriptions': total_prescriptions,
                    'lab_tests': total_lab_tests
                },
                'resources': {
                    'storage': storage_usage,
                    'database': database_usage,
                    'last_updated': datetime.datetime.now().isoformat()
                }
            }
        except Exception as e:
            logger.error(f"Failed to get system metrics: {str(e)}")
            raise


class OwnerCredentials:
    """Manages the owner credentials."""
    
    def __init__(self, credentials_file: str = 'owner_credentials.json') -> None:
        """Initialize the credentials manager."""
        self.credentials_file = credentials_file
        self.credentials = self._load_credentials()
        
        # Check if credentials need to be created
        if not self.credentials:
            self._create_initial_credentials()
    
    def _load_credentials(self) -> Dict[str, Any]:
        """Load credentials from the JSON file."""
        try:
            if os.path.exists(self.credentials_file):
                with open(self.credentials_file, 'r') as f:
                    return json.load(f)
            else:
                return {}
        except Exception as e:
            logger.error(f"Failed to load credentials: {str(e)}")
            return {}
    
    def _save_credentials(self) -> None:
        """Save credentials to the JSON file."""
        try:
            with open(self.credentials_file, 'w') as f:
                json.dump(self.credentials, f, indent=4)
        except Exception as e:
            logger.error(f"Failed to save credentials: {str(e)}")
    
    def _create_initial_credentials(self) -> None:
        """Create the initial owner credentials."""
        # Generate a secure initial password
        initial_password = SecurityManager.generate_secure_password()
        
        # Hash the password
        hashed_password = SecurityManager.hash_password(initial_password)
        
        # Create the credentials
        self.credentials = {
            'username': 'owner',
            'password_hash': hashed_password,
            'created_at': datetime.datetime.now().isoformat(),
            'last_login': None,
            'last_password_change': datetime.datetime.now().isoformat(),
            'require_password_change': True
        }
        
        # Save the credentials
        self._save_credentials()
        
        # Display the initial password to the user
        print("=" * 80)
        print("Initial Owner Credentials")
        print("=" * 80)
        print(f"Username: owner")
        print(f"Password: {initial_password}")
        print("=" * 80)
        print("IMPORTANT: Please save these credentials and change the password on first login.")
        print("=" * 80)
    
    def authenticate(self, username: str, password: str) -> bool:
        """Authenticate the user with the provided credentials."""
        if username != self.credentials.get('username'):
            return False
        
        # Verify the password
        if not SecurityManager.verify_password(self.credentials.get('password_hash', ''), password):
            return False
        
        # Update last login
        self.credentials['last_login'] = datetime.datetime.now().isoformat()
        self._save_credentials()
        
        return True
    
    def change_password(self, old_password: str, new_password: str) -> bool:
        """Change the owner password."""
        # Verify the old password
        if not SecurityManager.verify_password(self.credentials.get('password_hash', ''), old_password):
            return False
        
        # Hash the new password
        hashed_password = SecurityManager.hash_password(new_password)
        
        # Update the credentials
        self.credentials['password_hash'] = hashed_password
        self.credentials['last_password_change'] = datetime.datetime.now().isoformat()
        self.credentials['require_password_change'] = False
        
        # Save the credentials
        self._save_credentials()
        
        return True
    
    def reset_password(self) -> str:
        """Reset the owner password and return the new password."""
        # Generate a new password
        new_password = SecurityManager.generate_secure_password()
        
        # Hash the new password
        hashed_password = SecurityManager.hash_password(new_password)
        
        # Update the credentials
        self.credentials['password_hash'] = hashed_password
        self.credentials['last_password_change'] = datetime.datetime.now().isoformat()
        self.credentials['require_password_change'] = True
        
        # Save the credentials
        self._save_credentials()
        
        return new_password
    
    def requires_password_change(self) -> bool:
        """Check if the owner needs to change their password."""
        return self.credentials.get('require_password_change', True)


class OwnerApp:
    """Medical Practice Owner Control Application."""
    
    def __init__(self, config_file: str = 'owner_config.json') -> None:
        """Initialize the owner application."""
        self.config = self._load_config(config_file)
        self.credentials = OwnerCredentials()
        
        # Check if the user is authenticated
        self.authenticated = False
        
        # Create the main window
        self.root = tk.Tk()
        self.root.title("Medical Practice Owner Control")
        self.root.geometry("1200x800")
        self.root.minsize(800, 600)
        
        # Set up the UI
        self._show_login_screen()
    
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
    
    def _show_login_screen(self) -> None:
        """Show the login screen."""
        # Clear the window
        for widget in self.root.winfo_children():
            widget.destroy()
        
        # Create a frame for the login form
        login_frame = ttk.Frame(self.root, padding=20)
        login_frame.pack(expand=True)
        
        # Create the login form
        ttk.Label(login_frame, text="Medical Practice Owner Control", font=("TkDefaultFont", 16, "bold")).grid(row=0, column=0, columnspan=2, pady=(0, 20))
        
        ttk.Label(login_frame, text="Username:").grid(row=1, column=0, sticky="e", padx=10, pady=5)
        username_var = tk.StringVar()
        ttk.Entry(login_frame, textvariable=username_var, width=30).grid(row=1, column=1, sticky="w", padx=10, pady=5)
        
        ttk.Label(login_frame, text="Password:").grid(row=2, column=0, sticky="e", padx=10, pady=5)
        password_var = tk.StringVar()
        ttk.Entry(login_frame, textvariable=password_var, show="*", width=30).grid(row=2, column=1, sticky="w", padx=10, pady=5)
        
        # Create a button frame
        button_frame = ttk.Frame(login_frame)
        button_frame.grid(row=3, column=0, columnspan=2, pady=(20, 0))
        
        login_button = ttk.Button(
            button_frame,
            text="Login",
            command=lambda: self._handle_login(username_var.get(), password_var.get())
        )
        login_button.pack(side=tk.RIGHT, padx=5)
        
        # Bind Enter key to login
        self.root.bind("<Return>", lambda event: self._handle_login(username_var.get(), password_var.get()))
    
    def _handle_login(self, username: str, password: str) -> None:
        """Handle the login process."""
        if not username or not password:
            messagebox.showerror("Error", "Please enter both username and password.")
            return
        
        # Authenticate the user
        if self.credentials.authenticate(username, password):
            self.authenticated = True
            
            # Check if password change is required
            if self.credentials.requires_password_change():
                self._show_password_change_screen()
            else:
                self._load_main_app()
        else:
            messagebox.showerror("Error", "Invalid credentials. Please try again.")
    
    def _show_password_change_screen(self) -> None:
        """Show the password change screen."""
        # Clear the window
        for widget in self.root.winfo_children():
            widget.destroy()
        
        # Create a frame for the password change form
        password_frame = ttk.Frame(self.root, padding=20)
        password_frame.pack(expand=True)
        
        # Create the password change form
        ttk.Label(password_frame, text="Change Password", font=("TkDefaultFont", 16, "bold")).grid(row=0, column=0, columnspan=2, pady=(0, 20))
        
        ttk.Label(password_frame, text="Current Password:").grid(row=1, column=0, sticky="e", padx=10, pady=5)
        current_password_var = tk.StringVar()
        ttk.Entry(password_frame, textvariable=current_password_var, show="*", width=30).grid(row=1, column=1, sticky="w", padx=10, pady=5)
        
        ttk.Label(password_frame, text="New Password:").grid(row=2, column=0, sticky="e", padx=10, pady=5)
        new_password_var = tk.StringVar()
        ttk.Entry(password_frame, textvariable=new_password_var, show="*", width=30).grid(row=2, column=1, sticky="w", padx=10, pady=5)
        
        ttk.Label(password_frame, text="Confirm New Password:").grid(row=3, column=0, sticky="e", padx=10, pady=5)
        confirm_password_var = tk.StringVar()
        ttk.Entry(password_frame, textvariable=confirm_password_var, show="*", width=30).grid(row=3, column=1, sticky="w", padx=10, pady=5)
        
        # Create a button frame
        button_frame = ttk.Frame(password_frame)
        button_frame.grid(row=4, column=0, columnspan=2, pady=(20, 0))
        
        change_button = ttk.Button(
            button_frame,
            text="Change Password",
            command=lambda: self._handle_password_change(
                current_password_var.get(),
                new_password_var.get(),
                confirm_password_var.get()
            )
        )
        change_button.pack(side=tk.RIGHT, padx=5)
    
    def _handle_password_change(self, current_password: str, new_password: str, confirm_password: str) -> None:
        """Handle the password change process."""
        if not current_password or not new_password or not confirm_password:
            messagebox.showerror("Error", "Please fill in all fields.")
            return
        
        if new_password != confirm_password:
            messagebox.showerror("Error", "New password and confirmation do not match.")
            return
        
        if len(new_password) < 8:
            messagebox.showerror("Error", "New password must be at least 8 characters long.")
            return
        
        # Change the password
        if self.credentials.change_password(current_password, new_password):
            messagebox.showinfo("Success", "Password changed successfully.")
            self._load_main_app()
        else:
            messagebox.showerror("Error", "Current password is incorrect.")
    
    def _load_main_app(self) -> None:
        """Load the main application after successful authentication."""
        # Clear the window
        for widget in self.root.winfo_children():
            widget.destroy()
        
        # Initialize Azure services
        try:
            self.azure = AzureServices(self.config)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to initialize Azure services: {str(e)}")
            self._show_login_screen()
            return
        
        # Create a notebook with tabs
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create frames for tabs
        self.dashboard_frame = ttk.Frame(self.notebook)
        self.admins_frame = ttk.Frame(self.notebook)
        self.doctors_frame = ttk.Frame(self.notebook)
        self.data_frame = ttk.Frame(self.notebook)
        self.system_frame = ttk.Frame(self.notebook)
        self.settings_frame = ttk.Frame(self.notebook)
        
        # Add frames to notebook
        self.notebook.add(self.dashboard_frame, text="Dashboard")
        self.notebook.add(self.admins_frame, text="Admin Accounts")
        self.notebook.add(self.doctors_frame, text="Doctor Accounts")
        self.notebook.add(self.data_frame, text="Data Management")
        self.notebook.add(self.system_frame, text="System Operations")
        self.notebook.add(self.settings_frame, text="Settings")
        
        # Set up the dashboard tab
        self._setup_dashboard_tab()
        
        # Set up the admins tab
        self._setup_admins_tab()
        
        # Set up the doctors tab
        self._setup_doctors_tab()
        
        # Set up the data management tab
        self._setup_data_tab()
        
        # Set up the system operations tab
        self._setup_system_tab()
        
        # Set up the settings tab
        self._setup_settings_tab()
        
        # Load the initial data
        self._load_dashboard_data()
        self._load_admins()
        self._load_doctors()
    
    def _setup_dashboard_tab(self) -> None:
        """Set up the dashboard tab UI."""
        # Create a frame for the refresh button
        button_frame = ttk.Frame(self.dashboard_frame)
        button_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Add a refresh button
        refresh_button = ttk.Button(button_frame, text="Refresh", command=self._load_dashboard_data)
        refresh_button.pack(side=tk.LEFT, padx=5)
        
        # Create a frame for the system metrics
        metrics_frame = ttk.LabelFrame(self.dashboard_frame, text="System Metrics")
        metrics_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create a frame for the metrics content
        self.metrics_content = ttk.Frame(metrics_frame, padding=10)
        self.metrics_content.pack(fill=tk.BOTH, expand=True)
    
    def _setup_admins_tab(self) -> None:
        """Set up the admins tab UI."""
        # Create a frame for the buttons
        button_frame = ttk.Frame(self.admins_frame)
        button_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Add a refresh button
        refresh_button = ttk.Button(button_frame, text="Refresh", command=self._load_admins)
        refresh_button.pack(side=tk.LEFT, padx=5)
        
        # Add a new admin button
        new_admin_button = ttk.Button(button_frame, text="New Admin", command=self._show_new_admin_dialog)
        new_admin_button.pack(side=tk.LEFT, padx=5)
        
        # Create a frame for the treeview and scrollbar
        tree_frame = ttk.Frame(self.admins_frame)
        tree_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create scrollbar
        scrollbar = ttk.Scrollbar(tree_frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Create the treeview
        self.admins_tree = ttk.Treeview(
            tree_frame,
            columns=("id", "name", "email", "status"),
            show="headings",
            selectmode="browse",
            yscrollcommand=scrollbar.set
        )
        self.admins_tree.pack(fill=tk.BOTH, expand=True)
        
        # Configure the scrollbar
        scrollbar.config(command=self.admins_tree.yview)
        
        # Configure the treeview columns
        self.admins_tree.heading("id", text="ID")
        self.admins_tree.heading("name", text="Name")
        self.admins_tree.heading("email", text="Email")
        self.admins_tree.heading("status", text="Status")
        
        self.admins_tree.column("id", width=100)
        self.admins_tree.column("name", width=200)
        self.admins_tree.column("email", width=200)
        self.admins_tree.column("status", width=100)
        
        # Bind double-click event
        self.admins_tree.bind("<Double-1>", self._on_admin_double_click)
        
        # Create a right-click menu
        self.admin_menu = tk.Menu(self.root, tearoff=0)
        self.admin_menu.add_command(label="Edit", command=self._edit_selected_admin)
        self.admin_menu.add_command(label="Delete", command=self._delete_selected_admin)
        self.admin_menu.add_separator()
        self.admin_menu.add_command(label="Reset Password", command=self._reset_admin_password)
        
        # Bind right-click event
        self.admins_tree.bind("<Button-3>", self._on_admin_right_click)
    
    def _setup_doctors_tab(self) -> None:
        """Set up the doctors tab UI."""
        # Create a frame for the buttons
        button_frame = ttk.Frame(self.doctors_frame)
        button_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Add a refresh button
        refresh_button = ttk.Button(button_frame, text="Refresh", command=self._load_doctors)
        refresh_button.pack(side=tk.LEFT, padx=5)
        
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
        
        # Create a right-click menu
        self.doctor_menu = tk.Menu(self.root, tearoff=0)
        self.doctor_menu.add_command(label="View Details", command=self._view_doctor_details)
        self.doctor_menu.add_command(label="Reset Password", command=self._reset_doctor_password)
        self.doctor_menu.add_separator()
        self.doctor_menu.add_command(label="Deactivate All Accounts", command=self._deactivate_doctor_accounts)
        
        # Bind right-click event
        self.doctors_tree.bind("<Button-3>", self._on_doctor_right_click)
    
    def _setup_data_tab(self) -> None:
        """Set up the data management tab UI."""
        # Create a frame for export options
        export_frame = ttk.LabelFrame(self.data_frame, text="Data Export")
        export_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Create a container for the export options
        export_container = ttk.Frame(export_frame, padding=10)
        export_container.pack(fill=tk.X)
        
        # Collection selection
        ttk.Label(export_container, text="Collection:").grid(row=0, column=0, sticky="w", padx=5, pady=5)
        self.export_collection = tk.StringVar(value="users")
        ttk.Combobox(export_container, textvariable=self.export_collection, values=["users", "patients", "visits", "prescriptions", "labtests"]).grid(row=0, column=1, sticky="ew", padx=5, pady=5)
        
        # Format selection
        ttk.Label(export_container, text="Format:").grid(row=1, column=0, sticky="w", padx=5, pady=5)
        self.export_format = tk.StringVar(value="csv")
        ttk.Combobox(export_container, textvariable=self.export_format, values=["csv", "json"]).grid(row=1, column=1, sticky="ew", padx=5, pady=5)
        
        # Export button
        export_button = ttk.Button(export_container, text="Export Data", command=self._export_data)
        export_button.grid(row=2, column=0, columnspan=2, pady=(10, 0))
        
        # Create a frame for backup options
        backup_frame = ttk.LabelFrame(self.data_frame, text="Database Backup and Restore")
        backup_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Create a container for the backup options
        backup_container = ttk.Frame(backup_frame, padding=10)
        backup_container.pack(fill=tk.X)
        
        # Backup button
        backup_button = ttk.Button(backup_container, text="Create Database Backup", command=self._backup_database)
        backup_button.pack(side=tk.LEFT, padx=5)
        
        # Restore button
        restore_button = ttk.Button(backup_container, text="Restore from Backup", command=self._restore_database)
        restore_button.pack(side=tk.LEFT, padx=5)
    
    def _setup_system_tab(self) -> None:
        """Set up the system operations tab UI."""
        # Create a frame for Azure resources
        resources_frame = ttk.LabelFrame(self.system_frame, text="Azure Resources")
        resources_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Create a container for the resource options
        resources_container = ttk.Frame(resources_frame, padding=10)
        resources_container.pack(fill=tk.X)
        
        # View resources button
        view_resources_button = ttk.Button(resources_container, text="View Azure Resources", command=self._view_azure_resources)
        view_resources_button.pack(side=tk.LEFT, padx=5)
        
        # Create a frame for system logs
        logs_frame = ttk.LabelFrame(self.system_frame, text="System Logs")
        logs_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create a container for the logs
        logs_container = ttk.Frame(logs_frame, padding=10)
        logs_container.pack(fill=tk.BOTH, expand=True)
        
        # Create a text widget for the logs
        self.logs_text = tk.Text(logs_container, wrap=tk.WORD, width=80, height=20)
        self.logs_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        # Create a scrollbar for the logs
        logs_scrollbar = ttk.Scrollbar(logs_container, command=self.logs_text.yview)
        logs_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.logs_text.config(yscrollcommand=logs_scrollbar.set)
        
        # Add a button to refresh logs
        refresh_logs_button = ttk.Button(logs_frame, text="Refresh Logs", command=self._refresh_logs)
        refresh_logs_button.pack(pady=10)
    
    def _setup_settings_tab(self) -> None:
        """Set up the settings tab UI."""
        # Create a frame for the Azure settings
        azure_frame = ttk.LabelFrame(self.settings_frame, text="Azure Configuration")
        azure_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Create a container for the Azure settings
        azure_container = ttk.Frame(azure_frame, padding=10)
        azure_container.pack(fill=tk.BOTH, expand=True)
        
        # Create the Azure settings fields
        row = 0
        
        # Azure AD settings
        ttk.Label(azure_container, text="Azure AD Settings", font=("TkDefaultFont", 12, "bold")).grid(row=row, column=0, columnspan=2, sticky="w", pady=(0, 10))
        row += 1
        
        ttk.Label(azure_container, text="Tenant ID:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.tenant_id_var = tk.StringVar(value=self.config.get("azure_tenant_id", ""))
        ttk.Entry(azure_container, textvariable=self.tenant_id_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(azure_container, text="Client ID:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.client_id_var = tk.StringVar(value=self.config.get("azure_client_id", ""))
        ttk.Entry(azure_container, textvariable=self.client_id_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(azure_container, text="Client Secret:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.client_secret_var = tk.StringVar(value=self.config.get("azure_client_secret", ""))
        ttk.Entry(azure_container, textvariable=self.client_secret_var, width=50, show="*").grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(azure_container, text="Subscription ID:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.subscription_id_var = tk.StringVar(value=self.config.get("subscription_id", ""))
        ttk.Entry(azure_container, textvariable=self.subscription_id_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        # Add a separator
        ttk.Separator(azure_container, orient="horizontal").grid(row=row, column=0, columnspan=2, sticky="ew", pady=10)
        row += 1
        
        # Cosmos DB settings
        ttk.Label(azure_container, text="Cosmos DB Settings", font=("TkDefaultFont", 12, "bold")).grid(row=row, column=0, columnspan=2, sticky="w", pady=(0, 10))
        row += 1
        
        ttk.Label(azure_container, text="Cosmos Endpoint:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.cosmos_endpoint_var = tk.StringVar(value=self.config.get("cosmos_endpoint", ""))
        ttk.Entry(azure_container, textvariable=self.cosmos_endpoint_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(azure_container, text="Cosmos Key:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.cosmos_key_var = tk.StringVar(value=self.config.get("cosmos_key", ""))
        ttk.Entry(azure_container, textvariable=self.cosmos_key_var, width=50, show="*").grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(azure_container, text="Database Name:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.cosmos_database_var = tk.StringVar(value=self.config.get("cosmos_database", "medical_practice"))
        ttk.Entry(azure_container, textvariable=self.cosmos_database_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(azure_container, text="Users Container:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.cosmos_users_container_var = tk.StringVar(value=self.config.get("cosmos_users_container", "users"))
        ttk.Entry(azure_container, textvariable=self.cosmos_users_container_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        # Add a separator
        ttk.Separator(azure_container, orient="horizontal").grid(row=row, column=0, columnspan=2, sticky="ew", pady=10)
        row += 1
        
        # Storage settings
        ttk.Label(azure_container, text="Blob Storage Settings", font=("TkDefaultFont", 12, "bold")).grid(row=row, column=0, columnspan=2, sticky="w", pady=(0, 10))
        row += 1
        
        ttk.Label(azure_container, text="Storage Account:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.storage_account_var = tk.StringVar(value=self.config.get("storage_account_name", ""))
        ttk.Entry(azure_container, textvariable=self.storage_account_var, width=50).grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        ttk.Label(azure_container, text="Storage Key:").grid(row=row, column=0, sticky="w", padx=5, pady=5)
        self.storage_key_var = tk.StringVar(value=self.config.get("storage_account_key", ""))
        ttk.Entry(azure_container, textvariable=self.storage_key_var, width=50, show="*").grid(row=row, column=1, sticky="ew", padx=5, pady=5)
        row += 1
        
        # Add save button
        button_frame = ttk.Frame(azure_frame)
        button_frame.pack(fill=tk.X, pady=10)
        
        save_button = ttk.Button(button_frame, text="Save Settings", command=self._save_settings)
        save_button.pack(side=tk.RIGHT, padx=10)
        
        test_button = ttk.Button(button_frame, text="Test Connection", command=self._test_connection)
        test_button.pack(side=tk.RIGHT, padx=10)
        
        # Create a frame for the owner account
        owner_frame = ttk.LabelFrame(self.settings_frame, text="Owner Account")
        owner_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Create a container for the owner account options
        owner_container = ttk.Frame(owner_frame, padding=10)
        owner_container.pack(fill=tk.X)
        
        # Change password button
        change_password_button = ttk.Button(owner_container, text="Change Password", command=self._show_change_password_dialog)
        change_password_button.pack(side=tk.LEFT, padx=5)
    
    def _load_dashboard_data(self) -> None:
        """Load data for the dashboard."""
        try:
            # Clear the metrics content
            for widget in self.metrics_content.winfo_children():
                widget.destroy()
            
            # Add a loading label
            loading_label = ttk.Label(self.metrics_content, text="Loading metrics...")
            loading_label.pack()
            
            # Start loading in a separate thread
            threading.Thread(target=self._load_dashboard_thread).start()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load dashboard data: {str(e)}")
    
    def _load_dashboard_thread(self) -> None:
        """Load dashboard data in a separate thread."""
        try:
            # Get system metrics
            metrics = self.azure.get_system_metrics()
            
            # Update the UI in the main thread
            self.root.after(0, lambda: self._update_dashboard_ui(metrics))
        except Exception as e:
            # Show error message in the main thread
            self.root.after(0, lambda: messagebox.showerror("Error", f"Failed to load metrics: {str(e)}"))
    
    def _update_dashboard_ui(self, metrics: Dict[str, Any]) -> None:
        """Update the dashboard UI with the loaded metrics."""
        # Clear the metrics content
        for widget in self.metrics_content.winfo_children():
            widget.destroy()
        
        # Create a frame for each section
        accounts_frame = ttk.LabelFrame(self.metrics_content, text="Accounts")
        accounts_frame.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)
        
        data_frame = ttk.LabelFrame(self.metrics_content, text="Data")
        data_frame.grid(row=0, column=1, sticky="nsew", padx=10, pady=10)
        
        resources_frame = ttk.LabelFrame(self.metrics_content, text="Resources")
        resources_frame.grid(row=1, column=0, columnspan=2, sticky="nsew", padx=10, pady=10)
        
        # Configure grid
        self.metrics_content.grid_columnconfigure(0, weight=1)
        self.metrics_content.grid_columnconfigure(1, weight=1)
        self.metrics_content.grid_rowconfigure(0, weight=1)
        self.metrics_content.grid_rowconfigure(1, weight=1)
        
        # Populate accounts section
        accounts = metrics.get('accounts', {})
        row = 0
        
        # Doctors
        ttk.Label(accounts_frame, text="Doctors:").grid(row=row, column=0, sticky="w", padx=5, pady=2)
        ttk.Label(accounts_frame, text=f"Active: {accounts.get('doctors', {}).get('active', 0)}").grid(row=row, column=1, sticky="w", padx=5, pady=2)
        row += 1
        
        ttk.Label(accounts_frame, text="").grid(row=row, column=0, sticky="w", padx=5, pady=2)
        ttk.Label(accounts_frame, text=f"Inactive: {accounts.get('doctors', {}).get('inactive', 0)}").grid(row=row, column=1, sticky="w", padx=5, pady=2)
        row += 1
        
        ttk.Label(accounts_frame, text="").grid(row=row, column=0, sticky="w", padx=5, pady=2)
        ttk.Label(accounts_frame, text=f"Total: {accounts.get('doctors', {}).get('total', 0)}").grid(row=row, column=1, sticky="w", padx=5, pady=2)
        row += 1
        
        # Admins
        ttk.Label(accounts_frame, text="Admins:").grid(row=row, column=0, sticky="w", padx=5, pady=2)
        ttk.Label(accounts_frame, text=f"{accounts.get('admins', 0)}").grid(row=row, column=1, sticky="w", padx=5, pady=2)
        row += 1
        
        # Pharmacies
        ttk.Label(accounts_frame, text="Pharmacies:").grid(row=row, column=0, sticky="w", padx=5, pady=2)
        ttk.Label(accounts_frame, text=f"{accounts.get('pharmacies', 0)}").grid(row=row, column=1, sticky="w", padx=5, pady=2)
        row += 1
        
        # Labs
        ttk.Label(accounts_frame, text="Labs:").grid(row=row, column=0, sticky="w", padx=5, pady=2)
        ttk.Label(accounts_frame, text=f"{accounts.get('labs', 0)}").grid(row=row, column=1, sticky="w", padx=5, pady=2)
        row += 1
        
        # Populate data section
        data = metrics.get('data', {})
        row = 0
        
        # Patients
        ttk.Label(data_frame, text="Patients:").grid(row=row, column=0, sticky="w", padx=5, pady=2)
        ttk.Label(data_frame, text=f"{data.get('patients', 0)}").grid(row=row, column=1, sticky="w", padx=5, pady=2)
        row += 1
        
        # Visits
        ttk.Label(data_frame, text="Visits:").grid(row=row, column=0, sticky="w", padx=5, pady=2)
        ttk.Label(data_frame, text=f"{data.get('visits', 0)}").grid(row=row, column=1, sticky="w", padx=5, pady=2)
        row += 1
        
        # Prescriptions
        ttk.Label(data_frame, text="Prescriptions:").grid(row=row, column=0, sticky="w", padx=5, pady=2)
        ttk.Label(data_frame, text=f"{data.get('prescriptions', 0)}").grid(row=row, column=1, sticky="w", padx=5, pady=2)
        row += 1
        
        # Lab tests
        ttk.Label(data_frame, text="Lab Tests:").grid(row=row, column=0, sticky="w", padx=5, pady=2)
        ttk.Label(data_frame, text=f"{data.get('lab_tests', 0)}").grid(row=row, column=1, sticky="w", padx=5, pady=2)
        row += 1
        
        # Populate resources section
        resources = metrics.get('resources', {})
        
        # Storage
        storage = resources.get('storage', {})
        storage_frame = ttk.Frame(resources_frame)
        storage_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(storage_frame, text="Storage Usage:").pack(side=tk.LEFT, padx=5)
        ttk.Label(storage_frame, text=f"{storage.get('used_gb', 0)} GB / {storage.get('total_gb', 0)} GB ({storage.get('percent_used', 0)}%)").pack(side=tk.LEFT, padx=5)
        
        # Create a progress bar for storage
        storage_progress = ttk.Progressbar(storage_frame, orient=tk.HORIZONTAL, length=200, mode='determinate')
        storage_progress.pack(side=tk.LEFT, padx=5)
        storage_progress['value'] = storage.get('percent_used', 0)
        
        # Database
        database = resources.get('database', {})
        database_frame = ttk.Frame(resources_frame)
        database_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(database_frame, text="Database Usage:").pack(side=tk.LEFT, padx=5)
        ttk.Label(database_frame, text=f"{database.get('ru_consumed', 0)} RU/s / {database.get('ru_provisioned', 0)} RU/s ({database.get('percent_used', 0)}%)").pack(side=tk.LEFT, padx=5)
        
        # Create a progress bar for database
        database_progress = ttk.Progressbar(database_frame, orient=tk.HORIZONTAL, length=200, mode='determinate')
        database_progress.pack(side=tk.LEFT, padx=5)
        database_progress['value'] = database.get('percent_used', 0)
        
        # Last updated
        last_updated = resources.get('last_updated', '')
        last_updated_frame = ttk.Frame(resources_frame)
        last_updated_frame.pack(fill=tk.X, padx=10, pady=5)
        
        try:
            last_updated_dt = datetime.datetime.fromisoformat(last_updated.replace('Z', '+00:00'))
            last_updated_str = last_updated_dt.strftime("%Y-%m-%d %H:%M:%S")
        except:
            last_updated_str = last_updated
        
        ttk.Label(last_updated_frame, text=f"Last Updated: {last_updated_str}").pack(side=tk.LEFT, padx=5)
    
    def _load_admins(self) -> None:
        """Load admin accounts from the database."""
        # Clear the treeview
        self.admins_tree.delete(*self.admins_tree.get_children())
        
        try:
            # Start loading in a separate thread
            threading.Thread(target=self._load_admins_thread).start()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load admins: {str(e)}")
    
    def _load_admins_thread(self) -> None:
        """Load admin accounts in a separate thread."""
        try:
            # Get admins from Azure
            admins = self.azure.get_admin_accounts()
            
            # Sort admins by name
            admins.sort(key=lambda x: x.get('displayName', ''))
            
            # Update the UI in the main thread
            self.root.after(0, lambda: self._populate_admins_tree(admins))
        except Exception as e:
            # Show error message in the main thread
            self.root.after(0, lambda: messagebox.showerror("Error", f"Failed to load admins: {str(e)}"))
    
    def _populate_admins_tree(self, admins: List[Dict[str, Any]]) -> None:
        """Populate the admins treeview with data."""
        # Clear the treeview
        self.admins_tree.delete(*self.admins_tree.get_children())
        
        for admin in admins:
            # Get admin data
            admin_id = admin.get('id', '')
            name = admin.get('displayName', '')
            email = admin.get('email', '')
            is_active = admin.get('isActive', False)
            
            # Format the status string
            status = "Active" if is_active else "Inactive"
            
            # Add to treeview
            self.admins_tree.insert(
                "",
                "end",
                values=(admin_id, name, email, status),
                tags=(admin_id,)
            )
    
    def _load_doctors(self) -> None:
        """Load doctor accounts from the database."""
        # Clear the treeview
        self.doctors_tree.delete(*self.doctors_tree.get_children())
        
        try:
            # Start loading in a separate thread
            threading.Thread(target=self._load_doctors_thread).start()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load doctors: {str(e)}")
    
    def _load_doctors_thread(self) -> None:
        """Load doctor accounts in a separate thread."""
        try:
            # Get doctors from Azure
            doctors = self.azure.get_doctor_accounts()
            
            # Sort doctors by name
            doctors.sort(key=lambda x: x.get('displayName', ''))
            
            # Update the UI in the main thread
            self.root.after(0, lambda: self._populate_doctors_tree(doctors))
        except Exception as e:
            # Show error message in the main thread
            self.root.after(0, lambda: messagebox.showerror("Error", f"Failed to load doctors: {str(e)}"))
    
    def _populate_doctors_tree(self, doctors: List[Dict[str, Any]]) -> None:
        """Populate the doctors treeview with data."""
        # Clear the treeview
        self.doctors_tree.delete(*self.doctors_tree.get_children())
        
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
            
            # Add to treeview
            self.doctors_tree.insert(
                "",
                "end",
                values=(doctor_id, name, email, status, pharmacy, lab, subscription),
                tags=(doctor_id,)
            )
    
    def _on_admin_double_click(self, event) -> None:
        """Handle double-click on an admin in the treeview."""
        self._edit_selected_admin()
    
    def _on_admin_right_click(self, event) -> None:
        """Handle right-click on an admin in the treeview."""
        # Select the item under the cursor
        iid = self.admins_tree.identify_row(event.y)
        if iid:
            self.admins_tree.selection_set(iid)
            self.admin_menu.post(event.x_root, event.y_root)
    
    def _on_doctor_right_click(self, event) -> None:
        """Handle right-click on a doctor in the treeview."""
        # Select the item under the cursor
        iid = self.doctors_tree.identify_row(event.y)
        if iid:
            self.doctors_tree.selection_set(iid)
            self.doctor_menu.post(event.x_root, event.y_root)
    
    def _show_new_admin_dialog(self) -> None:
        """Show a dialog to create a new admin account."""
        # Create a top-level window
        dialog = tk.Toplevel(self.root)
        dialog.title("Create New Admin")
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
        
        # Permissions
        ttk.Label(form_frame, text="Permissions:").grid(row=3, column=0, sticky="w", padx=5, pady=5)
        permissions_frame = ttk.Frame(form_frame)
        permissions_frame.grid(row=3, column=1, sticky="w", padx=5, pady=5)
        
        manage_accounts_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(permissions_frame, text="Manage Accounts", variable=manage_accounts_var).grid(row=0, column=0, sticky="w")
        
        view_reports_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(permissions_frame, text="View Reports", variable=view_reports_var).grid(row=1, column=0, sticky="w")
        
        manage_settings_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(permissions_frame, text="Manage Settings", variable=manage_settings_var).grid(row=2, column=0, sticky="w")
        
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
            command=lambda: self._create_admin(
                dialog,
                result_text,
                first_name_var.get(),
                last_name_var.get(),
                email_var.get(),
                {
                    'manageAccounts': manage_accounts_var.get(),
                    'viewReports': view_reports_var.get(),
                    'manageSettings': manage_settings_var.get(),
                }
            )
        )
        create_button.pack(side=tk.RIGHT, padx=5)
        
        cancel_button = ttk.Button(button_frame, text="Close", command=dialog.destroy)
        cancel_button.pack(side=tk.RIGHT, padx=5)
    
    def _create_admin(
        self,
        dialog: tk.Toplevel,
        result_text: tk.Text,
        first_name: str,
        last_name: str,
        email: str,
        permissions: Dict[str, bool]
    ) -> None:
        """Create a new admin account."""
        # Validate the inputs
        if not first_name or not last_name or not email:
            messagebox.showerror("Error", "First name, last name, and email are required.")
            return
        
        try:
            # Create the admin data
            admin_data = {
                'first_name': first_name,
                'last_name': last_name,
                'email': email,
                'permissions': permissions
            }
            
            # Create the admin account
            result = self.azure.create_admin_account(admin_data)
            
            # Update the result text
            result_text.config(state=tk.NORMAL)
            result_text.delete(1.0, tk.END)
            
            result_text.insert(tk.END, "Admin account created successfully!\n\n")
            result_text.insert(tk.END, f"Admin ID: {result['admin_id']}\n")
            result_text.insert(tk.END, f"Admin Email: {result['admin_email']}\n")
            result_text.insert(tk.END, f"Admin Password: {result['admin_password']}\n")
            
            result_text.config(state=tk.DISABLED)
            
            # Reload the admins list
            self._load_admins()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to create admin account: {str(e)}")
    
    def _edit_selected_admin(self) -> None:
        """Edit the selected admin account."""
        # Get the selected admin
        selected = self.admins_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select an admin first.")
            return
        
        admin_id = self.admins_tree.item(selected[0], "values")[0]
        
        # Get the admin data
        try:
            admins = self.azure.get_admin_accounts()
            admin = next((a for a in admins if a.get('id') == admin_id), None)
            
            if not admin:
                messagebox.showerror("Error", f"Admin with ID {admin_id} not found.")
                return
            
            # Create a top-level window
            dialog = tk.Toplevel(self.root)
            dialog.title("Edit Admin")
            dialog.geometry("500x400")
            dialog.transient(self.root)
            dialog.grab_set()
            
            # Create a frame for the form
            form_frame = ttk.Frame(dialog, padding=10)
            form_frame.pack(fill=tk.BOTH, expand=True)
            
            # Create the form fields
            ttk.Label(form_frame, text="ID:").grid(row=0, column=0, sticky="w", padx=5, pady=5)
            id_var = tk.StringVar(value=admin.get('id', ''))
            ttk.Entry(form_frame, textvariable=id_var, width=30, state="readonly").grid(row=0, column=1, sticky="ew", padx=5, pady=5)
            
            ttk.Label(form_frame, text="First Name:").grid(row=1, column=0, sticky="w", padx=5, pady=5)
            first_name_var = tk.StringVar(value=admin.get('firstName', ''))
            ttk.Entry(form_frame, textvariable=first_name_var, width=30).grid(row=1, column=1, sticky="ew", padx=5, pady=5)
            
            ttk.Label(form_frame, text="Last Name:").grid(row=2, column=0, sticky="w", padx=5, pady=5)
            last_name_var = tk.StringVar(value=admin.get('lastName', ''))
            ttk.Entry(form_frame, textvariable=last_name_var, width=30).grid(row=2, column=1, sticky="ew", padx=5, pady=5)
            
            ttk.Label(form_frame, text="Email:").grid(row=3, column=0, sticky="w", padx=5, pady=5)
            email_var = tk.StringVar(value=admin.get('email', ''))
            ttk.Entry(form_frame, textvariable=email_var, width=30).grid(row=3, column=1, sticky="ew", padx=5, pady=5)
            
            # Permissions
            ttk.Label(form_frame, text="Permissions:").grid(row=4, column=0, sticky="w", padx=5, pady=5)
            permissions_frame = ttk.Frame(form_frame)
            permissions_frame.grid(row=4, column=1, sticky="w", padx=5, pady=5)
            
            permissions = admin.get('permissions', {})
            
            manage_accounts_var = tk.BooleanVar(value=permissions.get('manageAccounts', True))
            ttk.Checkbutton(permissions_frame, text="Manage Accounts", variable=manage_accounts_var).grid(row=0, column=0, sticky="w")
            
            view_reports_var = tk.BooleanVar(value=permissions.get('viewReports', True))
            ttk.Checkbutton(permissions_frame, text="View Reports", variable=view_reports_var).grid(row=1, column=0, sticky="w")
            
            manage_settings_var = tk.BooleanVar(value=permissions.get('manageSettings', True))
            ttk.Checkbutton(permissions_frame, text="Manage Settings", variable=manage_settings_var).grid(row=2, column=0, sticky="w")
            
            ttk.Label(form_frame, text="Active:").grid(row=5, column=0, sticky="w", padx=5, pady=5)
            active_var = tk.BooleanVar(value=admin.get('isActive', True))
            ttk.Checkbutton(form_frame, variable=active_var).grid(row=5, column=1, sticky="w", padx=5, pady=5)
            
            # Create buttons
            button_frame = ttk.Frame(dialog, padding=10)
            button_frame.pack(fill=tk.X)
            
            save_button = ttk.Button(
                button_frame,
                text="Save",
                command=lambda: self._update_admin(
                    dialog,
                    admin_id,
                    first_name_var.get(),
                    last_name_var.get(),
                    email_var.get(),
                    {
                        'manageAccounts': manage_accounts_var.get(),
                        'viewReports': view_reports_var.get(),
                        'manageSettings': manage_settings_var.get(),
                    },
                    active_var.get()
                )
            )
            save_button.pack(side=tk.RIGHT, padx=5)
            
            cancel_button = ttk.Button(button_frame, text="Cancel", command=dialog.destroy)
            cancel_button.pack(side=tk.RIGHT, padx=5)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to get admin data: {str(e)}")
    
    def _update_admin(
        self,
        dialog: tk.Toplevel,
        admin_id: str,
        first_name: str,
        last_name: str,
        email: str,
        permissions: Dict[str, bool],
        active: bool
    ) -> None:
        """Update an admin account."""
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
                'permissions': permissions,
                'isActive': active,
                'displayName': f"{first_name} {last_name}"
            }
            
            # Update the admin account
            self.azure.update_admin_account(admin_id, update_data)
            
            # Close the dialog
            dialog.destroy()
            
            # Reload the admins list
            self._load_admins()
            
            messagebox.showinfo("Success", "Admin account updated successfully.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to update admin account: {str(e)}")
    
    def _delete_selected_admin(self) -> None:
        """Delete the selected admin account."""
        # Get the selected admin
        selected = self.admins_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select an admin first.")
            return
        
        admin_id = self.admins_tree.item(selected[0], "values")[0]
        admin_name = self.admins_tree.item(selected[0], "values")[1]
        
        # Confirm deletion
        if not messagebox.askyesno("Confirm Deletion", f"Are you sure you want to delete the admin account for {admin_name}?"):
            return
        
        try:
            # Delete the admin account
            self.azure.delete_admin_account(admin_id)
            
            # Reload the admins list
            self._load_admins()
            
            messagebox.showinfo("Success", "Admin account deleted successfully.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to delete admin account: {str(e)}")
    
    def _reset_admin_password(self) -> None:
        """Reset the password for the selected admin account."""
        # Get the selected admin
        selected = self.admins_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select an admin first.")
            return
        
        admin_id = self.admins_tree.item(selected[0], "values")[0]
        admin_name = self.admins_tree.item(selected[0], "values")[1]
        
        # Confirm reset
        if not messagebox.askyesno("Confirm Password Reset", f"Are you sure you want to reset the password for {admin_name}?"):
            return
        
        try:
            # Reset the password
            new_password = self.azure.reset_password(admin_id)
            
            # Show the new password
            messagebox.showinfo(
                "Password Reset",
                f"Password reset successfully.\n\nNew Password: {new_password}\n\nPlease make sure to share this password securely with the user."
            )
        except Exception as e:
            messagebox.showerror("Error", f"Failed to reset password: {str(e)}")
    
    def _view_doctor_details(self) -> None:
        """View details for the selected doctor account."""
        # Get the selected doctor
        selected = self.doctors_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select a doctor first.")
            return
        
        doctor_id = self.doctors_tree.item(selected[0], "values")[0]
        
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
    
    def _reset_doctor_password(self) -> None:
        """Reset the password for the selected doctor account."""
        # Get the selected doctor
        selected = self.doctors_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select a doctor first.")
            return
        
        doctor_id = self.doctors_tree.item(selected[0], "values")[0]
        doctor_name = self.doctors_tree.item(selected[0], "values")[1]
        
        # Confirm reset
        if not messagebox.askyesno("Confirm Password Reset", f"Are you sure you want to reset the password for {doctor_name}?"):
            return
        
        try:
            # Reset the password
            new_password = self.azure.reset_password(doctor_id)
            
            # Show the new password
            messagebox.showinfo(
                "Password Reset",
                f"Password reset successfully.\n\nNew Password: {new_password}\n\nPlease make sure to share this password securely with the user."
            )
        except Exception as e:
            messagebox.showerror("Error", f"Failed to reset password: {str(e)}")
    
    def _deactivate_doctor_accounts(self) -> None:
        """Deactivate all accounts for the selected doctor."""
        # Get the selected doctor
        selected = self.doctors_tree.selection()
        if not selected:
            messagebox.showinfo("Info", "Please select a doctor first.")
            return
        
        doctor_id = self.doctors_tree.item(selected[0], "values")[0]
        doctor_name = self.doctors_tree.item(selected[0], "values")[1]
        
        # Confirm deactivation
        if not messagebox.askyesno("Confirm Deactivation", f"Are you sure you want to deactivate all accounts for {doctor_name}?"):
            return
        
        try:
            # Deactivate the accounts
            self.azure.deactivate_all_accounts_for_doctor(doctor_id)
            
            # Reload the doctors list
            self._load_doctors()
            
            messagebox.showinfo("Success", "All accounts deactivated successfully.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to deactivate accounts: {str(e)}")
    
    def _export_data(self) -> None:
        """Export data from a collection."""
        collection = self.export_collection.get()
        output_format = self.export_format.get()
        
        try:
            # Export the data
            output_file = self.azure.export_data(collection, output_format)
            
            messagebox.showinfo("Export Complete", f"Data exported successfully to {output_file}")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to export data: {str(e)}")
    
    def _backup_database(self) -> None:
        """Create a backup of the database."""
        try:
            # Create the backup
            backup_file = self.azure.backup_database()
            
            messagebox.showinfo("Backup Complete", f"Database backed up successfully to {backup_file}")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to backup database: {str(e)}")
    
    def _restore_database(self) -> None:
        """Restore the database from a backup."""
        # Ask for the backup file
        backup_file = filedialog.askopenfilename(
            title="Select Backup File",
            filetypes=[("ZIP Files", "*.zip")],
            initialdir="backups"
        )
        
        if not backup_file:
            return
        
        # Confirm restoration
        if not messagebox.askyesno("Confirm Restore", "Are you sure you want to restore the database from this backup? This will overwrite existing data."):
            return
        
        try:
            # Restore the database
            self.azure.restore_database(backup_file)
            
            messagebox.showinfo("Restore Complete", "Database restored successfully.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to restore database: {str(e)}")
    
    def _view_azure_resources(self) -> None:
        """View Azure resources."""
        messagebox.showinfo("Azure Resources", "This feature is not implemented yet.")
    
    def _refresh_logs(self) -> None:
        """Refresh the system logs."""
        try:
            # Clear the logs text
            self.logs_text.config(state=tk.NORMAL)
            self.logs_text.delete(1.0, tk.END)
            
            # Load the logs from the log file
            if os.path.exists("owner_app.log"):
                with open("owner_app.log", "r") as f:
                    logs = f.readlines()
                
                # Show the last 100 lines
                for line in logs[-100:]:
                    self.logs_text.insert(tk.END, line)
            
            self.logs_text.config(state=tk.DISABLED)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to refresh logs: {str(e)}")
    
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
            with open('owner_config.json', 'w') as f:
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
            
            # Try to get system metrics
            self.azure.get_system_metrics()
            
            messagebox.showinfo("Success", "Connection test successful.")
        except Exception as e:
            messagebox.showerror("Error", f"Connection test failed: {str(e)}")
    
    def _show_change_password_dialog(self) -> None:
        """Show the change password dialog."""
        # Create a top-level window
        dialog = tk.Toplevel(self.root)
        dialog.title("Change Owner Password")
        dialog.geometry("400x200")
        dialog.transient(self.root)
        dialog.grab_set()
        
        # Create a frame for the form
        form_frame = ttk.Frame(dialog, padding=10)
        form_frame.pack(fill=tk.BOTH, expand=True)
        
        # Create the form fields
        ttk.Label(form_frame, text="Current Password:").grid(row=0, column=0, sticky="w", padx=5, pady=5)
        current_password_var = tk.StringVar()
        ttk.Entry(form_frame, textvariable=current_password_var, show="*", width=30).grid(row=0, column=1, sticky="ew", padx=5, pady=5)
        
        ttk.Label(form_frame, text="New Password:").grid(row=1, column=0, sticky="w", padx=5, pady=5)
        new_password_var = tk.StringVar()
        ttk.Entry(form_frame, textvariable=new_password_var, show="*", width=30).grid(row=1, column=1, sticky="ew", padx=5, pady=5)
        
        ttk.Label(form_frame, text="Confirm New Password:").grid(row=2, column=0, sticky="w", padx=5, pady=5)
        confirm_password_var = tk.StringVar()
        ttk.Entry(form_frame, textvariable=confirm_password_var, show="*", width=30).grid(row=2, column=1, sticky="ew", padx=5, pady=5)
        
        # Create buttons
        button_frame = ttk.Frame(dialog, padding=10)
        button_frame.pack(fill=tk.X)
        
        change_button = ttk.Button(
            button_frame,
            text="Change Password",
            command=lambda: self._handle_change_password(
                dialog,
                current_password_var.get(),
                new_password_var.get(),
                confirm_password_var.get()
            )
        )
        change_button.pack(side=tk.RIGHT, padx=5)
        
        cancel_button = ttk.Button(button_frame, text="Cancel", command=dialog.destroy)
        cancel_button.pack(side=tk.RIGHT, padx=5)
    
    def _handle_change_password(
        self,
        dialog: tk.Toplevel,
        current_password: str,
        new_password: str,
        confirm_password: str
    ) -> None:
        """Handle the change password process."""
        # Validate the inputs
        if not current_password or not new_password or not confirm_password:
            messagebox.showerror("Error", "Please fill in all fields.")
            return
        
        if new_password != confirm_password:
            messagebox.showerror("Error", "New password and confirmation do not match.")
            return
        
        if len(new_password) < 8:
            messagebox.showerror("Error", "New password must be at least 8 characters long.")
            return
        
        # Change the password
        if self.credentials.change_password(current_password, new_password):
            messagebox.showinfo("Success", "Password changed successfully.")
            dialog.destroy()
        else:
            messagebox.showerror("Error", "Current password is incorrect.")
    
    def run(self) -> None:
        """Run the application."""
        self.root.mainloop()


if __name__ == "__main__":
    app = OwnerApp()
    app.run()