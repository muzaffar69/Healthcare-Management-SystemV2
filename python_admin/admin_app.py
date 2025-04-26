import os
import sys
import sqlite3
import hashlib
import secrets
import string
import tkinter as tk
from tkinter import ttk, messagebox, simpledialog
from datetime import datetime
import json
import re

class AdminApplication:
    def __init__(self, root):
        self.root = root
        self.root.title("Medical Practice Admin")
        self.root.geometry("900x600")
        self.root.resizable(True, True)
        
        # Set application style
        self.style = ttk.Style()
        self.style.theme_use('clam')
        self.configure_styles()
        
        # Database connection
        self.db_path = self.get_db_path()
        self.conn = None
        self.connect_to_database()
        
        # Create UI
        self.create_ui()
        
        # Load initial data
        self.load_doctors()
        self.load_pharmacies()
        self.load_labs()

    def configure_styles(self):
        # Configure colors
        primary_color = "#7B63FF"  # Purple
        secondary_color = "#00D68F"  # Green
        warning_color = "#FF7D69"  # Orange/red
        text_color = "#3A3F5A"  # Dark blue/grey
        bg_color = "#F8F9FE"  # Light background
        
        # Configure button styles
        self.style.configure(
            'Primary.TButton', 
            background=primary_color, 
            foreground='white',
            padding=(10, 5),
            font=('Helvetica', 10, 'bold')
        )
        
        self.style.configure(
            'Secondary.TButton', 
            background=secondary_color, 
            foreground='white',
            padding=(10, 5),
            font=('Helvetica', 10, 'bold')
        )
        
        self.style.configure(
            'Warning.TButton', 
            background=warning_color, 
            foreground='white',
            padding=(10, 5),
            font=('Helvetica', 10, 'bold')
        )
        
        # Configure frame styles
        self.style.configure(
            'Card.TFrame', 
            background='white',
            relief='raised',
            borderwidth=1
        )
        
        # Configure label styles
        self.style.configure(
            'Title.TLabel',
            font=('Helvetica', 16, 'bold'),
            foreground=text_color,
            background=bg_color,
            padding=(0, 10)
        )
        
        self.style.configure(
            'Subtitle.TLabel',
            font=('Helvetica', 12, 'bold'),
            foreground=text_color,
            background='white',
            padding=(5, 5)
        )
        
        # Configure treeview styles
        self.style.configure(
            'Treeview',
            font=('Helvetica', 10),
            rowheight=30,
            background='white',
            fieldbackground='white',
            foreground=text_color
        )
        
        self.style.configure(
            'Treeview.Heading',
            font=('Helvetica', 11, 'bold'),
            background=primary_color,
            foreground='white'
        )
        
        # Set root background color
        self.root.configure(background=bg_color)

    def get_db_path(self):
        # For development, create the database in the current directory
        return os.path.join(os.path.dirname(os.path.abspath(__file__)), 'admin_database.db')

    def connect_to_database(self):
        try:
            # Connect to database
            self.conn = sqlite3.connect(self.db_path)
            cursor = self.conn.cursor()
            
            # Create tables if they don't exist
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS doctors (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT NOT NULL UNIQUE,
                    password TEXT NOT NULL,
                    name TEXT,
                    specialty TEXT,
                    email TEXT,
                    phone TEXT,
                    created_at TEXT
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS pharmacies (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    address TEXT,
                    phone TEXT,
                    access_code TEXT NOT NULL UNIQUE,
                    doctor_id INTEGER,
                    created_at TEXT,
                    FOREIGN KEY (doctor_id) REFERENCES doctors (id)
                )
            ''')
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS laboratories (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    address TEXT,
                    phone TEXT,
                    access_code TEXT NOT NULL UNIQUE,
                    doctor_id INTEGER,
                    created_at TEXT,
                    FOREIGN KEY (doctor_id) REFERENCES doctors (id)
                )
            ''')
            
            self.conn.commit()
            
        except sqlite3.Error as e:
            messagebox.showerror("Database Error", f"Error connecting to database: {e}")
            sys.exit(1)

    def create_ui(self):
        # Create notebook (tabs)
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=15, pady=15)
        
        # Create tabs
        self.doctors_tab = ttk.Frame(self.notebook, style='Card.TFrame')
        self.pharmacies_tab = ttk.Frame(self.notebook, style='Card.TFrame')
        self.labs_tab = ttk.Frame(self.notebook, style='Card.TFrame')
        
        self.notebook.add(self.doctors_tab, text='Doctors')
        self.notebook.add(self.pharmacies_tab, text='Pharmacies')
        self.notebook.add(self.labs_tab, text='Laboratories')
        
        # Create content for each tab
        self.create_doctors_tab()
        self.create_pharmacies_tab()
        self.create_labs_tab()

    def create_doctors_tab(self):
        # Top frame for title and add button
        top_frame = ttk.Frame(self.doctors_tab)
        top_frame.pack(fill=tk.X, padx=10, pady=10)
        
        title_label = ttk.Label(top_frame, text="Doctor Accounts", style='Title.TLabel')
        title_label.pack(side=tk.LEFT)
        
        add_button = ttk.Button(
            top_frame, 
            text="Add New Doctor", 
            command=self.add_doctor,
            style='Primary.TButton'
        )
        add_button.pack(side=tk.RIGHT)
        
        # Create treeview for doctors list
        columns = ('id', 'username', 'name', 'specialty', 'email', 'phone', 'created_at')
        self.doctors_tree = ttk.Treeview(
            self.doctors_tab, 
            columns=columns, 
            show='headings',
            selectmode='browse'
        )
        
        # Define headings
        self.doctors_tree.heading('id', text='ID')
        self.doctors_tree.heading('username', text='Username')
        self.doctors_tree.heading('name', text='Name')
        self.doctors_tree.heading('specialty', text='Specialty')
        self.doctors_tree.heading('email', text='Email')
        self.doctors_tree.heading('phone', text='Phone')
        self.doctors_tree.heading('created_at', text='Created At')
        
        # Define columns
        self.doctors_tree.column('id', width=50)
        self.doctors_tree.column('username', width=150)
        self.doctors_tree.column('name', width=200)
        self.doctors_tree.column('specialty', width=150)
        self.doctors_tree.column('email', width=200)
        self.doctors_tree.column('phone', width=150)
        self.doctors_tree.column('created_at', width=150)
        
        # Add scrollbar
        scrollbar = ttk.Scrollbar(self.doctors_tab, orient=tk.VERTICAL, command=self.doctors_tree.yview)
        self.doctors_tree.configure(yscroll=scrollbar.set)
        
        # Pack widgets
        self.doctors_tree.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Add context menu for doctor actions
        self.doctors_tree.bind("<Button-3>", self.show_doctor_context_menu)
        self.doctors_tree.bind("<Double-1>", self.edit_doctor)

    def create_pharmacies_tab(self):
        # Top frame for title and add button
        top_frame = ttk.Frame(self.pharmacies_tab)
        top_frame.pack(fill=tk.X, padx=10, pady=10)
        
        title_label = ttk.Label(top_frame, text="Pharmacy Accounts", style='Title.TLabel')
        title_label.pack(side=tk.LEFT)
        
        add_button = ttk.Button(
            top_frame, 
            text="Add New Pharmacy", 
            command=self.add_pharmacy,
            style='Primary.TButton'
        )
        add_button.pack(side=tk.RIGHT)
        
        # Create treeview for pharmacies list
        columns = ('id', 'name', 'address', 'phone', 'access_code', 'doctor', 'created_at')
        self.pharmacies_tree = ttk.Treeview(
            self.pharmacies_tab, 
            columns=columns, 
            show='headings',
            selectmode='browse'
        )
        
        # Define headings
        self.pharmacies_tree.heading('id', text='ID')
        self.pharmacies_tree.heading('name', text='Name')
        self.pharmacies_tree.heading('address', text='Address')
        self.pharmacies_tree.heading('phone', text='Phone')
        self.pharmacies_tree.heading('access_code', text='Access Code')
        self.pharmacies_tree.heading('doctor', text='Doctor')
        self.pharmacies_tree.heading('created_at', text='Created At')
        
        # Define columns
        self.pharmacies_tree.column('id', width=50)
        self.pharmacies_tree.column('name', width=200)
        self.pharmacies_tree.column('address', width=200)
        self.pharmacies_tree.column('phone', width=150)
        self.pharmacies_tree.column('access_code', width=150)
        self.pharmacies_tree.column('doctor', width=200)
        self.pharmacies_tree.column('created_at', width=150)
        
        # Add scrollbar
        scrollbar = ttk.Scrollbar(self.pharmacies_tab, orient=tk.VERTICAL, command=self.pharmacies_tree.yview)
        self.pharmacies_tree.configure(yscroll=scrollbar.set)
        
        # Pack widgets
        self.pharmacies_tree.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Add context menu for pharmacy actions
        self.pharmacies_tree.bind("<Button-3>", self.show_pharmacy_context_menu)
        self.pharmacies_tree.bind("<Double-1>", self.edit_pharmacy)

    def create_labs_tab(self):
        # Top frame for title and add button
        top_frame = ttk.Frame(self.labs_tab)
        top_frame.pack(fill=tk.X, padx=10, pady=10)
        
        title_label = ttk.Label(top_frame, text="Laboratory Accounts", style='Title.TLabel')
        title_label.pack(side=tk.LEFT)
        
        add_button = ttk.Button(
            top_frame, 
            text="Add New Laboratory", 
            command=self.add_lab,
            style='Primary.TButton'
        )
        add_button.pack(side=tk.RIGHT)
        
        # Create treeview for labs list
        columns = ('id', 'name', 'address', 'phone', 'access_code', 'doctor', 'created_at')
        self.labs_tree = ttk.Treeview(
            self.labs_tab, 
            columns=columns, 
            show='headings',
            selectmode='browse'
        )
        
        # Define headings
        self.labs_tree.heading('id', text='ID')
        self.labs_tree.heading('name', text='Name')
        self.labs_tree.heading('address', text='Address')
        self.labs_tree.heading('phone', text='Phone')
        self.labs_tree.heading('access_code', text='Access Code')
        self.labs_tree.heading('doctor', text='Doctor')
        self.labs_tree.heading('created_at', text='Created At')
        
        # Define columns
        self.labs_tree.column('id', width=50)
        self.labs_tree.column('name', width=200)
        self.labs_tree.column('address', width=200)
        self.labs_tree.column('phone', width=150)
        self.labs_tree.column('access_code', width=150)
        self.labs_tree.column('doctor', width=200)
        self.labs_tree.column('created_at', width=150)
        
        # Add scrollbar
        scrollbar = ttk.Scrollbar(self.labs_tab, orient=tk.VERTICAL, command=self.labs_tree.yview)
        self.labs_tree.configure(yscroll=scrollbar.set)
        
        # Pack widgets
        self.labs_tree.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Add context menu for lab actions
        self.labs_tree.bind("<Button-3>", self.show_lab_context_menu)
        self.labs_tree.bind("<Double-1>", self.edit_lab)

    # Doctor CRUD operations
    def load_doctors(self):
        # Clear existing items
        for item in self.doctors_tree.get_children():
            self.doctors_tree.delete(item)
        
        try:
            cursor = self.conn.cursor()
            cursor.execute('''
                SELECT id, username, name, specialty, email, phone, created_at
                FROM doctors
                ORDER BY created_at DESC
            ''')
            
            for row in cursor.fetchall():
                self.doctors_tree.insert('', tk.END, values=row)
                
        except sqlite3.Error as e:
            messagebox.showerror("Database Error", f"Error loading doctors: {e}")

    def add_doctor(self):
        # Create dialog window
        dialog = tk.Toplevel(self.root)
        dialog.title("Add New Doctor")
        dialog.geometry("400x450")
        dialog.resizable(False, False)
        dialog.transient(self.root)
        dialog.grab_set()
        
        # Create form fields
        ttk.Label(dialog, text="Username:").grid(row=0, column=0, padx=10, pady=10, sticky=tk.W)
        username_entry = ttk.Entry(dialog, width=30)
        username_entry.grid(row=0, column=1, padx=10, pady=10)
        
        ttk.Label(dialog, text="Password:").grid(row=1, column=0, padx=10, pady=10, sticky=tk.W)
        password_entry = ttk.Entry(dialog, width=30, show="*")
        password_entry.grid(row=1, column=1, padx=10, pady=10)
        
        ttk.Label(dialog, text="Confirm Password:").grid(row=2, column=0, padx=10, pady=10, sticky=tk.W)
        confirm_password_entry = ttk.Entry(dialog, width=30, show="*")
        confirm_password_entry.grid(row=2, column=1, padx=10, pady=10)
        
        ttk.Label(dialog, text="Name:").grid(row=3, column=0, padx=10, pady=10, sticky=tk.W)
        name_entry = ttk.Entry(dialog, width=30)
        name_entry.grid(row=3, column=1, padx=10, pady=10)
        
        ttk.Label(dialog, text="Specialty:").grid(row=4, column=0, padx=10, pady=10, sticky=tk.W)
        specialty_entry = ttk.Entry(dialog, width=30)
        specialty_entry.grid(row=4, column=1, padx=10, pady=10)
        
        ttk.Label(dialog, text="Email:").grid(row=5, column=0, padx=10, pady=10, sticky=tk.W)
        email_entry = ttk.Entry(dialog, width=30)
        email_entry.grid(row=5, column=1, padx=10, pady=10)
        
        ttk.Label(dialog, text="Phone:").grid(row=6, column=0, padx=10, pady=10, sticky=tk.W)
        phone_entry = ttk.Entry(dialog, width=30)
        phone_entry.grid(row=6, column=1, padx=10, pady=10)
        
        # Error label
        error_label = ttk.Label(dialog, text="", foreground="red")
        error_label.grid(row=7, column=0, columnspan=2, padx=10, pady=10)
        
        # Create and pharmacy/lab checkboxes
        create_related_accounts_var = tk.BooleanVar(value=True)
        create_related_accounts_cb = ttk.Checkbutton(
            dialog, 
            text="Create associated pharmacy and lab accounts",
            variable=create_related_accounts_var
        )
        create_related_accounts_cb.grid(row=8, column=0, columnspan=2, padx=10, pady=10, sticky=tk.W)
        
        # Buttons
        button_frame = ttk.Frame(dialog)
        button_frame.grid(row=9, column=0, columnspan=2, padx=10, pady=10)
        
        def validate_and_save():
            # Validate form
            username = username_entry.get().strip()
            password = password_entry.get()
            confirm_password = confirm_password_entry.get()
            name = name_entry.get().strip()
            specialty = specialty_entry.get().strip()
            email = email_entry.get().strip()
            phone = phone_entry.get().strip()
            
            # Basic validation
            if not username:
                error_label.config(text="Username is required")
                return
                
            if not password:
                error_label.config(text="Password is required")
                return
                
            if password != confirm_password:
                error_label.config(text="Passwords do not match")
                return
                
            if not name:
                error_label.config(text="Name is required")
                return
            
            # Email validation
            if email and not re.match(r"[^@]+@[^@]+\.[^@]+", email):
                error_label.config(text="Invalid email format")
                return
            
            try:
                # Hash password
                hashed_password = hashlib.sha256(password.encode()).hexdigest()
                
                # Insert into database
                cursor = self.conn.cursor()
                cursor.execute('''
                    INSERT INTO doctors 
                    (username, password, name, specialty, email, phone, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                ''', (
                    username, 
                    hashed_password, 
                    name, 
                    specialty, 
                    email, 
                    phone, 
                    datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                ))
                
                doctor_id = cursor.lastrowid
                
                self.conn.commit()
                
                # Create associated pharmacy and lab accounts if checked
                if create_related_accounts_var.get():
                    self.create_associated_accounts(doctor_id, name)
                
                # Refresh doctors list
                self.load_doctors()
                self.load_pharmacies()
                self.load_labs()
                
                # Close dialog
                dialog.destroy()
                
                messagebox.showinfo("Success", "Doctor account created successfully")
                
            except sqlite3.IntegrityError:
                error_label.config(text="Username already exists")
                
            except sqlite3.Error as e:
                error_label.config(text=f"Database error: {e}")
        
        ttk.Button(
            button_frame, 
            text="Save", 
            command=validate_and_save,
            style='Primary.TButton'
        ).pack(side=tk.LEFT, padx=5)
        
        ttk.Button(
            button_frame, 
            text="Cancel", 
            command=dialog.destroy,
            style='Warning.TButton'
        ).pack(side=tk.LEFT, padx=5)

    def edit_doctor(self, event=None):
        # Get selected item
        selection = self.doctors_tree.selection()
        if not selection:
            return
            
        # Get doctor data
        doctor_id = self.doctors_tree.item(selection[0], 'values')[0]
        
        try:
            cursor = self.conn.cursor()
            cursor.execute('''
                SELECT id, username, name, specialty, email, phone
                FROM doctors
                WHERE id = ?
            ''', (doctor_id,))
            
            doctor = cursor.fetchone()
            if not doctor:
                messagebox.showerror("Error", "Doctor not found")
                return
                
            # Create dialog window
            dialog = tk.Toplevel(self.root)
            dialog.title("Edit Doctor")
            dialog.geometry("400x400")
            dialog.resizable(False, False)
            dialog.transient(self.root)
            dialog.grab_set()
            
            # Create form fields
            ttk.Label(dialog, text="Username:").grid(row=0, column=0, padx=10, pady=10, sticky=tk.W)
            username_entry = ttk.Entry(dialog, width=30)
            username_entry.insert(0, doctor[1])
            username_entry.grid(row=0, column=1, padx=10, pady=10)
            username_entry.config(state='disabled')  # Username cannot be changed
            
            ttk.Label(dialog, text="New Password:").grid(row=1, column=0, padx=10, pady=10, sticky=tk.W)
            password_entry = ttk.Entry(dialog, width=30, show="*")
            password_entry.grid(row=1, column=1, padx=10, pady=10)
            
            ttk.Label(dialog, text="Confirm Password:").grid(row=2, column=0, padx=10, pady=10, sticky=tk.W)
            confirm_password_entry = ttk.Entry(dialog, width=30, show="*")
            confirm_password_entry.grid(row=2, column=1, padx=10, pady=10)
            
            ttk.Label(dialog, text="Name:").grid(row=3, column=0, padx=10, pady=10, sticky=tk.W)
            name_entry = ttk.Entry(dialog, width=30)
            name_entry.insert(0, doctor[2] or "")
            name_entry.grid(row=3, column=1, padx=10, pady=10)
            
            ttk.Label(dialog, text="Specialty:").grid(row=4, column=0, padx=10, pady=10, sticky=tk.W)
            specialty_entry = ttk.Entry(dialog, width=30)
            specialty_entry.insert(0, doctor[3] or "")
            specialty_entry.grid(row=4, column=1, padx=10, pady=10)
            
            ttk.Label(dialog, text="Email:").grid(row=5, column=0, padx=10, pady=10, sticky=tk.W)
            email_entry = ttk.Entry(dialog, width=30)
            email_entry.insert(0, doctor[4] or "")
            email_entry.grid(row=5, column=1, padx=10, pady=10)
            
            ttk.Label(dialog, text="Phone:").grid(row=6, column=0, padx=10, pady=10, sticky=tk.W)
            phone_entry = ttk.Entry(dialog, width=30)
            phone_entry.insert(0, doctor[5] or "")
            phone_entry.grid(row=6, column=1, padx=10, pady=10)
            
            # Error label
            error_label = ttk.Label(dialog, text="", foreground="red")
            error_label.grid(row=7, column=0, columnspan=2, padx=10, pady=10)
            
            # Buttons
            button_frame = ttk.Frame(dialog)
            button_frame.grid(row=8, column=0, columnspan=2, padx=10, pady=10)
            
            def validate_and_save():
                # Validate form
                password = password_entry.get()
                confirm_password = confirm_password_entry.get()
                name = name_entry.get().strip()
                specialty = specialty_entry.get().strip()
                email = email_entry.get().strip()
                phone = phone_entry.get().strip()
                
                # Basic validation
                if password and password != confirm_password:
                    error_label.config(text="Passwords do not match")
                    return
                    
                if not name:
                    error_label.config(text="Name is required")
                    return
                
                # Email validation
                if email and not re.match(r"[^@]+@[^@]+\.[^@]+", email):
                    error_label.config(text="Invalid email format")
                    return
                
                try:
                    # Update database
                    cursor = self.conn.cursor()
                    
                    if password:
                        # Hash new password
                        hashed_password = hashlib.sha256(password.encode()).hexdigest()
                        cursor.execute('''
                            UPDATE doctors
                            SET password = ?, name = ?, specialty = ?, email = ?, phone = ?
                            WHERE id = ?
                        ''', (
                            hashed_password, 
                            name, 
                            specialty, 
                            email, 
                            phone, 
                            doctor_id
                        ))
                    else:
                        cursor.execute('''
                            UPDATE doctors
                            SET name = ?, specialty = ?, email = ?, phone = ?
                            WHERE id = ?
                        ''', (
                            name, 
                            specialty, 
                            email, 
                            phone, 
                            doctor_id
                        ))
                    
                    self.conn.commit()
                    
                    # Refresh doctors list
                    self.load_doctors()
                    
                    # Close dialog
                    dialog.destroy()
                    
                    messagebox.showinfo("Success", "Doctor account updated successfully")
                    
                except sqlite3.Error as e:
                    error_label.config(text=f"Database error: {e}")
            
            ttk.Button(
                button_frame, 
                text="Save", 
                command=validate_and_save,
                style='Primary.TButton'
            ).pack(side=tk.LEFT, padx=5)
            
            ttk.Button(
                button_frame, 
                text="Cancel", 
                command=dialog.destroy,
                style='Warning.TButton'
            ).pack(side=tk.LEFT, padx=5)
                
        except sqlite3.Error as e:
            messagebox.showerror("Database Error", f"Error loading doctor: {e}")

    def delete_doctor(self):
        # Get selected item
        selection = self.doctors_tree.selection()
        if not selection:
            return
            
        # Get doctor data
        doctor_id = self.doctors_tree.item(selection[0], 'values')[0]
        doctor_name = self.doctors_tree.item(selection[0], 'values')[2]
        
        # Confirm deletion
        if not messagebox.askyesno("Confirm Delete", f"Are you sure you want to delete doctor '{doctor_name}' and all associated accounts?"):
            return
            
        try:
            cursor = self.conn.cursor()
            
            # Delete associated pharmacy and lab accounts
            cursor.execute("DELETE FROM pharmacies WHERE doctor_id = ?", (doctor_id,))
            cursor.execute("DELETE FROM laboratories WHERE doctor_id = ?", (doctor_id,))
            
            # Delete doctor
            cursor.execute("DELETE FROM doctors WHERE id = ?", (doctor_id,))
            
            self.conn.commit()
            
            # Refresh lists
            self.load_doctors()
            self.load_pharmacies()
            self.load_labs()
            
            messagebox.showinfo("Success", "Doctor and associated accounts deleted successfully")
            
        except sqlite3.Error as e:
            messagebox.showerror("Database Error", f"Error deleting doctor: {e}")

    def show_doctor_context_menu(self, event):
        # Get selected item
        selection = self.doctors_tree.selection()
        if not selection:
            return
            
        # Create context menu
        context_menu = tk.Menu(self.root, tearoff=0)
        context_menu.add_command(label="Edit", command=self.edit_doctor)
        context_menu.add_command(label="Delete", command=self.delete_doctor)
        context_menu.add_separator()
        context_menu.add_command(label="Create Associated Accounts", command=self.create_associated_accounts_for_selected)
        
        # Display context menu
        context_menu.post(event.x_root, event.y_root)

    def create_associated_accounts_for_selected(self):
        # Get selected item
        selection = self.doctors_tree.selection()
        if not selection:
            return
            
        # Get doctor data
        doctor_id = self.doctors_tree.item(selection[0], 'values')[0]
        doctor_name = self.doctors_tree.item(selection[0], 'values')[2]
        
        # Create associated accounts
        self.create_associated_accounts(doctor_id, doctor_name)
        
        # Refresh lists
        self.load_pharmacies()
        self.load_labs()

    def create_associated_accounts(self, doctor_id, doctor_name):
        try:
            # Check if accounts already exist
            cursor = self.conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM pharmacies WHERE doctor_id = ?", (doctor_id,))
            pharmacy_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM laboratories WHERE doctor_id = ?", (doctor_id,))
            lab_count = cursor.fetchone()[0]
            
            if pharmacy_count > 0 or lab_count > 0:
                # Confirm creation of additional accounts
                if not messagebox.askyesno(
                    "Confirm Creation", 
                    "Associated accounts already exist for this doctor. Create additional accounts?"
                ):
                    return
            
            # Generate pharmacy access code
            pharmacy_access_code = self.generate_access_code()
            
            # Create pharmacy account
            pharmacy_name = f"{doctor_name}'s Pharmacy"
            cursor.execute('''
                INSERT INTO pharmacies 
                (name, access_code, doctor_id, created_at)
                VALUES (?, ?, ?, ?)
            ''', (
                pharmacy_name,
                pharmacy_access_code,
                doctor_id,
                datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            ))
            
            # Generate lab access code
            lab_access_code = self.generate_access_code()
            
            # Create lab account
            lab_name = f"{doctor_name}'s Laboratory"
            cursor.execute('''
                INSERT INTO laboratories 
                (name, access_code, doctor_id, created_at)
                VALUES (?, ?, ?, ?)
            ''', (
                lab_name,
                lab_access_code,
                doctor_id,
                datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            ))
            
            self.conn.commit()
            
            # Show access codes
            messagebox.showinfo(
                "Account Created", 
                f"Associated accounts created successfully.\n\nPharmacy Access Code: {pharmacy_access_code}\nLaboratory Access Code: {lab_access_code}"
            )
            
        except sqlite3.Error as e:
            messagebox.showerror("Database Error", f"Error creating associated accounts: {e}")

    # Pharmacy CRUD operations
    def load_pharmacies(self):
        # Clear existing items
        for item in self.pharmacies_tree.get_children():
            self.pharmacies_tree.delete(item)
        
        try:
            cursor = self.conn.cursor()
            cursor.execute('''
                SELECT p.id, p.name, p.address, p.phone, p.access_code, d.name as doctor_name, p.created_at
                FROM pharmacies p
                LEFT JOIN doctors d ON p.doctor_id = d.id
                ORDER BY p.created_at DESC
            ''')
            
            for row in cursor.fetchall():
                self.pharmacies_tree.insert('', tk.END, values=row)
                
        except sqlite3.Error as e:
            messagebox.showerror("Database Error", f"Error loading pharmacies: {e}")

    def add_pharmacy(self):
        # Create dialog window
        dialog = tk.Toplevel(self.root)
        dialog.title("Add New Pharmacy")
        dialog.geometry("400x400")
        dialog.resizable(False, False)
        dialog.transient(self.root)
        dialog.grab_set()
        
        # Create form fields
        ttk.Label(dialog, text="Name:").grid(row=0, column=0, padx=10, pady=10, sticky=tk.W)
        name_entry = ttk.Entry(dialog, width=30)
        name_entry.grid(row=0, column=1, padx=10, pady=10)
        
        ttk.Label(dialog, text="Address:").grid(row=1, column=0, padx=10, pady=10, sticky=tk.W)
        address_entry = ttk.Entry(dialog, width=30)
        address_entry.grid(row=1, column=1, padx=10, pady=10)
        
        ttk.Label(dialog, text="Phone:").grid(row=2, column=0, padx=10, pady=10, sticky=tk.W)
        phone_entry = ttk.Entry(dialog, width=30)
        phone_entry.grid(row=2, column=1, padx=10, pady=10)
        
        ttk.Label(dialog, text="Doctor:").grid(row=3, column=0, padx=10, pady=10, sticky=tk.W)
        
        # Get doctors for dropdown
        doctors = []
        try:
            cursor = self.conn.cursor()
            cursor.execute("SELECT id, name FROM doctors ORDER BY name")
            doctors = cursor.fetchall()
        except sqlite3.Error:
            pass
            
        # Create doctor dropdown
        doctor_var = tk.StringVar()
        doctor_dropdown = ttk.Combobox(dialog, textvariable=doctor_var, width=27)
        doctor_dropdown['values'] = [f"{d[0]} - {d[1]}" for d in doctors]
        doctor_dropdown.grid(row=3, column=1, padx=10, pady=10)
        
        # Generate access code
        access_code = self.generate_access_code()
        
        ttk.Label(dialog, text="Access Code:").grid(row=4, column=0, padx=10, pady=10, sticky=tk.W)
        access_code_entry = ttk.Entry(dialog, width=30)
        access_code_entry.insert(0, access_code)
        access_code_entry.grid(row=4, column=1, padx=10, pady=10)
        
        # Regenerate button
        def regenerate_code():
            new_code = self.generate_access_code()
            access_code_entry.delete(0, tk.END)
            access_code_entry.insert(0, new_code)
            
        ttk.Button(
            dialog, 
            text="Regenerate", 
            command=regenerate_code,
            style='Secondary.TButton'
        ).grid(row=4, column=2, padx=5, pady=10)
        
        # Error label
        error_label = ttk.Label(dialog, text="", foreground="red")
        error_label.grid(row=5, column=0, columnspan=2, padx=10, pady=10)
        
        # Buttons
        button_frame = ttk.Frame(dialog)
        button_frame.grid(row=6, column=0, columnspan=2, padx=10, pady=10)
        
        def validate_and_save():
            # Validate form
            name = name_entry.get().strip()
            address = address_entry.get().strip()
            phone = phone_entry.get().strip()
            access_code = access_code_entry.get().strip()
            
            # Get selected doctor
            doctor_id = None
            if doctor_var.get():
                doctor_id = doctor_var.get().split(" - ")[0]
            
            # Basic validation
            if not name:
                error_label.config(text="Name is required")
                return
                
            if not access_code:
                error_label.config(text="Access code is required")
                return
            
            try:
                # Insert into database
                cursor = self.conn.cursor()
                cursor.execute('''
                    INSERT INTO pharmacies 
                    (name, address, phone, access_code, doctor_id, created_at)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (
                    name, 
                    address, 
                    phone, 
                    access_code, 
                    doctor_id,
                    datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                ))
                
                self.conn.commit()
                
                # Refresh list
                self.load_pharmacies()
                
                # Close dialog
                dialog.destroy()
                
                messagebox.showinfo("Success", "Pharmacy account created successfully")
                
            except sqlite3.IntegrityError:
                error_label.config(text="Access code already exists")
                
            except sqlite3.Error as e:
                error_label.config(text=f"Database error: {e}")
        
        ttk.Button(
            button_frame, 
            text="Save", 
            command=validate_and_save,
            style='Primary.TButton'
        ).pack(side=tk.LEFT, padx=5)
        
        ttk.Button(
            button_frame, 
            text="Cancel", 
            command=dialog.destroy,
            style='Warning.TButton'
        ).pack(side=tk.LEFT, padx=5)

    def edit_pharmacy(self, event=None):
        # Get selected item
        selection = self.pharmacies_tree.selection()
        if not selection:
            return
            
        # Get pharmacy data
        pharmacy_values = self.pharmacies_tree.item(selection[0], 'values')
        pharmacy_id = pharmacy_values[0]
        
        try:
            cursor = self.conn.cursor()
            cursor.execute('''
                SELECT p.id, p.name, p.address, p.phone, p.access_code, p.doctor_id
                FROM pharmacies p
                WHERE p.id = ?
            ''', (pharmacy_id,))
            
            pharmacy = cursor.fetchone()
            if not pharmacy:
                messagebox.showerror("Error", "Pharmacy not found")
                return
                
            # Create dialog window
            dialog = tk.Toplevel(self.root)
            dialog.title("Edit Pharmacy")
            dialog.geometry("400x350")
            dialog.resizable(False, False)
            dialog.transient(self.root)
            dialog.grab_set()
            
            # Create form fields
            ttk.Label(dialog, text="Name:").grid(row=0, column=0, padx=10, pady=10, sticky=tk.W)
            name_entry = ttk.Entry(dialog, width=30)
            name_entry.insert(0, pharmacy[1] or "")
            name_entry.grid(row=0, column=1, padx=10, pady=10)
            
            ttk.Label(dialog, text="Address:").grid(row=1, column=0, padx=10, pady=10, sticky=tk.W)
            address_entry = ttk.Entry(dialog, width=30)
            address_entry.insert(0, pharmacy[2] or "")
            address_entry.grid(row=1, column=1, padx=10, pady=10)
            
            ttk.Label(dialog, text="Phone:").grid(row=2, column=0, padx=10, pady=10, sticky=tk.W)
            phone_entry = ttk.Entry(dialog, width=30)
            phone_entry.insert(0, pharmacy[3] or "")
            phone_entry.grid(row=2, column=1, padx=10, pady=10)
            
            ttk.Label(dialog, text="Doctor:").grid(row=3, column=0, padx=10, pady=10, sticky=tk.W)
            
            # Get doctors for dropdown
            doctors = []
            try:
                cursor = self.conn.cursor()
                cursor.execute("SELECT id, name FROM doctors ORDER BY name")
                doctors = cursor.fetchall()
            except sqlite3.Error:
                pass
                
            # Create doctor dropdown
            doctor_var = tk.StringVar()
            doctor_dropdown = ttk.Combobox(dialog, textvariable=doctor_var, width=27)
            doctor_dropdown['values'] = [""] + [f"{d[0]} - {d[1]}" for d in doctors]
            doctor_dropdown.grid(row=3, column=1, padx=10, pady=10)
            
            # Set current doctor
            if pharmacy[5]:
                for d in doctors:
                    if str(d[0]) == str(pharmacy[5]):
                        doctor_var.set(f"{d[0]} - {d[1]}")
                        break
            
            ttk.Label(dialog, text="Access Code:").grid(row=4, column=0, padx=10, pady=10, sticky=tk.W)
            access_code_entry = ttk.Entry(dialog, width=30)
            access_code_entry.insert(0, pharmacy[4])
            access_code_entry.grid(row=4, column=1, padx=10, pady=10)
            
            # Regenerate button
            def regenerate_code():
                if messagebox.askyesno("Confirm", "Are you sure you want to regenerate the access code? The old code will no longer work."):
                    new_code = self.generate_access_code()
                    access_code_entry.delete(0, tk.END)
                    access_code_entry.insert(0, new_code)
                
            ttk.Button(
                dialog, 
                text="Regenerate", 
                command=regenerate_code,
                style='Secondary.TButton'
            ).grid(row=4, column=2, padx=5, pady=10)
            
            # Error label
            error_label = ttk.Label(dialog, text="", foreground="red")
            error_label.grid(row=5, column=0, columnspan=2, padx=10, pady=10)
            
            # Buttons
            button_frame = ttk.Frame(dialog)
            button_frame.grid(row=6, column=0, columnspan=2, padx=10, pady=10)
            
            def validate_and_save():
                # Validate form
                name = name_entry.get().strip()
                address = address_entry.get().strip()
                phone = phone_entry.get().strip()
                access_code = access_code_entry.get().strip()
                
                # Get selected doctor
                doctor_id = None
                if doctor_var.get():
                    try:
                        doctor_id = doctor_var.get().split(" - ")[0]
                    except:
                        pass
                
                # Basic validation
                if not name:
                    error_label.config(text="Name is required")
                    return
                    
                if not access_code:
                    error_label.config(text="Access code is required")
                    return
                
                try:
                    # Update database
                    cursor = self.conn.cursor()
                    cursor.execute('''
                        UPDATE pharmacies
                        SET name = ?, address = ?, phone = ?, access_code = ?, doctor_id = ?
                        WHERE id = ?
                    ''', (
                        name, 
                        address, 
                        phone, 
                        access_code, 
                        doctor_id,
                        pharmacy_id
                    ))
                    
                    self.conn.commit()
                    
                    # Refresh list
                    self.load_pharmacies()
                    
                    # Close dialog
                    dialog.destroy()
                    
                    messagebox.showinfo("Success", "Pharmacy account updated successfully")
                    
                except sqlite3.IntegrityError:
                    error_label.config(text="Access code already exists")
                    
                except sqlite3.Error as e:
                    error_label.config(text=f"Database error: {e}")
            
            ttk.Button(
                button_frame, 
                text="Save", 
                command=validate_and_save,
                style='Primary.TButton'
            ).pack(side=tk.LEFT, padx=5)
            
            ttk.Button(
                button_frame, 
                text="Cancel", 
                command=dialog.destroy,
                style='Warning.TButton'
            ).pack(side=tk.LEFT, padx=5)
                
        except sqlite3.Error as e:
            messagebox.showerror("Database Error", f"Error loading pharmacy: {e}")

    def delete_pharmacy(self):
        # Get selected item
        selection = self.pharmacies_tree.selection()
        if not selection:
            return
            
        # Get pharmacy data
        pharmacy_id = self.pharmacies_tree.item(selection[0], 'values')[0]
        pharmacy_name = self.pharmacies_tree.item(selection[0], 'values')[1]
        
        # Confirm deletion
        if not messagebox.askyesno("Confirm Delete", f"Are you sure you want to delete pharmacy '{pharmacy_name}'?"):
            return
            
        try:
            cursor = self.conn.cursor()
            cursor.execute("DELETE FROM pharmacies WHERE id = ?", (pharmacy_id,))
            self.conn.commit()
            
            # Refresh list
            self.load_pharmacies()
            
            messagebox.showinfo("Success", "Pharmacy deleted successfully")
            
        except sqlite3.Error as e:
            messagebox.showerror("Database Error", f"Error deleting pharmacy: {e}")

    def show_pharmacy_context_menu(self, event):
        # Get selected item
        selection = self.pharmacies_tree.selection()
        if not selection:
            return
            
        # Create context menu
        context_menu = tk.Menu(self.root, tearoff=0)
        context_menu.add_command(label="Edit", command=self.edit_pharmacy)
        context_menu.add_command(label="Delete", command=self.delete_pharmacy)
        
        # Display context menu
        context_menu.post(event.x_root, event.y_root)

    # Lab CRUD operations
    def load_labs(self):
        # Clear existing items
        for item in self.labs_tree.get_children():
            self.labs_tree.delete(item)
        
        try:
            cursor = self.conn.cursor()
            cursor.execute('''
                SELECT l.id, l.name, l.address, l.phone, l.access_code, d.name as doctor_name, l.created_at
                FROM laboratories l
                LEFT JOIN doctors d ON l.doctor_id = d.id
                ORDER BY l.created_at DESC
            ''')
            
            for row in cursor.fetchall():
                self.labs_tree.insert('', tk.END, values=row)
                
        except sqlite3.Error as e:
            messagebox.showerror("Database Error", f"Error loading laboratories: {e}")

    def add_lab(self):
        # Create dialog window
        dialog = tk.Toplevel(self.root)
        dialog.title("Add New Laboratory")
        dialog.geometry("400x400")
        dialog.resizable(False, False)
        dialog.transient(self.root)
        dialog.grab_set()
        
        # Create form fields
        ttk.Label(dialog, text="Name:").grid(row=0, column=0, padx=10, pady=10, sticky=tk.W)
        name_entry = ttk.Entry(dialog, width=30)
        name_entry.grid(row=0, column=1, padx=10, pady=10)
        
        ttk.Label(dialog, text="Address:").grid(row=1, column=0, padx=10, pady=10, sticky=tk.W)
        address_entry = ttk.Entry(dialog, width=30)
        address_entry.grid(row=1, column=1, padx=10, pady=10)
        
        ttk.Label(dialog, text="Phone:").grid(row=2, column=0, padx=10, pady=10, sticky=tk.W)
        phone_entry = ttk.Entry(dialog, width=30)
        phone_entry.grid(row=2, column=1, padx=10, pady=10)
        
        ttk.Label(dialog, text="Doctor:").grid(row=3, column=0, padx=10, pady=10, sticky=tk.W)
        
        # Get doctors for dropdown
        doctors = []
        try:
            cursor = self.conn.cursor()
            cursor.execute("SELECT id, name FROM doctors ORDER BY name")
            doctors = cursor.fetchall()
        except sqlite3.Error:
            pass
            
        # Create doctor dropdown
        doctor_var = tk.StringVar()
        doctor_dropdown = ttk.Combobox(dialog, textvariable=doctor_var, width=27)
        doctor_dropdown['values'] = [f"{d[0]} - {d[1]}" for d in doctors]
        doctor_dropdown.grid(row=3, column=1, padx=10, pady=10)
        
        # Generate access code
        access_code = self.generate_access_code()
        
        ttk.Label(dialog, text="Access Code:").grid(row=4, column=0, padx=10, pady=10, sticky=tk.W)
        access_code_entry = ttk.Entry(dialog, width=30)
        access_code_entry.insert(0, access_code)
        access_code_entry.grid(row=4, column=1, padx=10, pady=10)
        
        # Regenerate button
        def regenerate_code():
            new_code = self.generate_access_code()
            access_code_entry.delete(0, tk.END)
            access_code_entry.insert(0, new_code)
            
        ttk.Button(
            dialog, 
            text="Regenerate", 
            command=regenerate_code,
            style='Secondary.TButton'
        ).grid(row=4, column=2, padx=5, pady=10)
        
        # Error label
        error_label = ttk.Label(dialog, text="", foreground="red")
        error_label.grid(row=5, column=0, columnspan=2, padx=10, pady=10)
        
        # Buttons
        button_frame = ttk.Frame(dialog)
        button_frame.grid(row=6, column=0, columnspan=2, padx=10, pady=10)
        
        def validate_and_save():
            # Validate form
            name = name_entry.get().strip()
            address = address_entry.get().strip()
            phone = phone_entry.get().strip()
            access_code = access_code_entry.get().strip()
            
            # Get selected doctor
            doctor_id = None
            if doctor_var.get():
                doctor_id = doctor_var.get().split(" - ")[0]
            
            # Basic validation
            if not name:
                error_label.config(text="Name is required")
                return
                
            if not access_code:
                error_label.config(text="Access code is required")
                return
            
            try:
                # Insert into database
                cursor = self.conn.cursor()
                cursor.execute('''
                    INSERT INTO laboratories 
                    (name, address, phone, access_code, doctor_id, created_at)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (
                    name, 
                    address, 
                    phone, 
                    access_code, 
                    doctor_id,
                    datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                ))
                
                self.conn.commit()
                
                # Refresh list
                self.load_labs()
                
                # Close dialog
                dialog.destroy()
                
                messagebox.showinfo("Success", "Laboratory account created successfully")
                
            except sqlite3.IntegrityError:
                error_label.config(text="Access code already exists")
                
            except sqlite3.Error as e:
                error_label.config(text=f"Database error: {e}")
        
        ttk.Button(
            button_frame, 
            text="Save", 
            command=validate_and_save,
            style='Primary.TButton'
        ).pack(side=tk.LEFT, padx=5)
        
        ttk.Button(
            button_frame, 
            text="Cancel", 
            command=dialog.destroy,
            style='Warning.TButton'
        ).pack(side=tk.LEFT, padx=5)

    def edit_lab(self, event=None):
        # Similar to edit_pharmacy with appropriate adjustments
        # Get selected item
        selection = self.labs_tree.selection()
        if not selection:
            return
            
        # Get lab data
        lab_values = self.labs_tree.item(selection[0], 'values')
        lab_id = lab_values[0]
        
        try:
            cursor = self.conn.cursor()
            cursor.execute('''
                SELECT l.id, l.name, l.address, l.phone, l.access_code, l.doctor_id
                FROM laboratories l
                WHERE l.id = ?
            ''', (lab_id,))
            
            lab = cursor.fetchone()
            if not lab:
                messagebox.showerror("Error", "Laboratory not found")
                return
                
            # Create dialog window
            dialog = tk.Toplevel(self.root)
            dialog.title("Edit Laboratory")
            dialog.geometry("400x350")
            dialog.resizable(False, False)
            dialog.transient(self.root)
            dialog.grab_set()
            
            # Create form fields (similar to edit_pharmacy)
            ttk.Label(dialog, text="Name:").grid(row=0, column=0, padx=10, pady=10, sticky=tk.W)
            name_entry = ttk.Entry(dialog, width=30)
            name_entry.insert(0, lab[1] or "")
            name_entry.grid(row=0, column=1, padx=10, pady=10)
            
            ttk.Label(dialog, text="Address:").grid(row=1, column=0, padx=10, pady=10, sticky=tk.W)
            address_entry = ttk.Entry(dialog, width=30)
            address_entry.insert(0, lab[2] or "")
            address_entry.grid(row=1, column=1, padx=10, pady=10)
            
            ttk.Label(dialog, text="Phone:").grid(row=2, column=0, padx=10, pady=10, sticky=tk.W)
            phone_entry = ttk.Entry(dialog, width=30)
            phone_entry.insert(0, lab[3] or "")
            phone_entry.grid(row=2, column=1, padx=10, pady=10)
            
            ttk.Label(dialog, text="Doctor:").grid(row=3, column=0, padx=10, pady=10, sticky=tk.W)
            
            # Get doctors for dropdown
            doctors = []
            try:
                cursor = self.conn.cursor()
                cursor.execute("SELECT id, name FROM doctors ORDER BY name")
                doctors = cursor.fetchall()
            except sqlite3.Error:
                pass
                
            # Create doctor dropdown
            doctor_var = tk.StringVar()
            doctor_dropdown = ttk.Combobox(dialog, textvariable=doctor_var, width=27)
            doctor_dropdown['values'] = [""] + [f"{d[0]} - {d[1]}" for d in doctors]
            doctor_dropdown.grid(row=3, column=1, padx=10, pady=10)
            
            # Set current doctor
            if lab[5]:
                for d in doctors:
                    if str(d[0]) == str(lab[5]):
                        doctor_var.set(f"{d[0]} - {d[1]}")
                        break
            
            ttk.Label(dialog, text="Access Code:").grid(row=4, column=0, padx=10, pady=10, sticky=tk.W)
            access_code_entry = ttk.Entry(dialog, width=30)
            access_code_entry.insert(0, lab[4])
            access_code_entry.grid(row=4, column=1, padx=10, pady=10)
            
            # Regenerate button
            def regenerate_code():
                if messagebox.askyesno("Confirm", "Are you sure you want to regenerate the access code? The old code will no longer work."):
                    new_code = self.generate_access_code()
                    access_code_entry.delete(0, tk.END)
                    access_code_entry.insert(0, new_code)
                
            ttk.Button(
                dialog, 
                text="Regenerate", 
                command=regenerate_code,
                style='Secondary.TButton'
            ).grid(row=4, column=2, padx=5, pady=10)
            
            # Error label
            error_label = ttk.Label(dialog, text="", foreground="red")
            error_label.grid(row=5, column=0, columnspan=2, padx=10, pady=10)
            
            # Buttons
            button_frame = ttk.Frame(dialog)
            button_frame.grid(row=6, column=0, columnspan=2, padx=10, pady=10)
            
            def validate_and_save():
                # Validate form
                name = name_entry.get().strip()
                address = address_entry.get().strip()
                phone = phone_entry.get().strip()
                access_code = access_code_entry.get().strip()
                
                # Get selected doctor
                doctor_id = None
                if doctor_var.get():
                    try:
                        doctor_id = doctor_var.get().split(" - ")[0]
                    except:
                        pass
                
                # Basic validation
                if not name:
                    error_label.config(text="Name is required")
                    return
                    
                if not access_code:
                    error_label.config(text="Access code is required")
                    return
                
                try:
                    # Update database
                    cursor = self.conn.cursor()
                    cursor.execute('''
                        UPDATE laboratories
                        SET name = ?, address = ?, phone = ?, access_code = ?, doctor_id = ?
                        WHERE id = ?
                    ''', (
                        name, 
                        address, 
                        phone, 
                        access_code, 
                        doctor_id,
                        lab_id
                    ))
                    
                    self.conn.commit()
                    
                    # Refresh list
                    self.load_labs()
                    
                    # Close dialog
                    dialog.destroy()
                    
                    messagebox.showinfo("Success", "Laboratory account updated successfully")
                    
                except sqlite3.IntegrityError:
                    error_label.config(text="Access code already exists")
                    
                except sqlite3.Error as e:
                    error_label.config(text=f"Database error: {e}")
            
            ttk.Button(
                button_frame, 
                text="Save", 
                command=validate_and_save,
                style='Primary.TButton'
            ).pack(side=tk.LEFT, padx=5)
            
            ttk.Button(
                button_frame, 
                text="Cancel", 
                command=dialog.destroy,
                style='Warning.TButton'
            ).pack(side=tk.LEFT, padx=5)
                
        except sqlite3.Error as e:
            messagebox.showerror("Database Error", f"Error loading laboratory: {e}")

    def delete_lab(self):
        # Get selected item
        selection = self.labs_tree.selection()
        if not selection:
            return
            
        # Get lab data
        lab_id = self.labs_tree.item(selection[0], 'values')[0]
        lab_name = self.labs_tree.item(selection[0], 'values')[1]
        
        # Confirm deletion
        if not messagebox.askyesno("Confirm Delete", f"Are you sure you want to delete laboratory '{lab_name}'?"):
            return
            
        try:
            cursor = self.conn.cursor()
            cursor.execute("DELETE FROM laboratories WHERE id = ?", (lab_id,))
            self.conn.commit()
            
            # Refresh list
            self.load_labs()
            
            messagebox.showinfo("Success", "Laboratory deleted successfully")
            
        except sqlite3.Error as e:
            messagebox.showerror("Database Error", f"Error deleting laboratory: {e}")

    def show_lab_context_menu(self, event):
        # Get selected item
        selection = self.labs_tree.selection()
        if not selection:
            return
            
        # Create context menu
        context_menu = tk.Menu(self.root, tearoff=0)
        context_menu.add_command(label="Edit", command=self.edit_lab)
        context_menu.add_command(label="Delete", command=self.delete_lab)
        
        # Display context menu
        context_menu.post(event.x_root, event.y_root)

    # Helper methods
    def generate_access_code(self):
        # Generate a random 8-character access code
        characters = string.ascii_uppercase + string.digits
        code = ''.join(secrets.choice(characters) for _ in range(8))
        
        # Check if code already exists
        try:
            cursor = self.conn.cursor()
            
            # Check in pharmacies
            cursor.execute("SELECT COUNT(*) FROM pharmacies WHERE access_code = ?", (code,))
            if cursor.fetchone()[0] > 0:
                return self.generate_access_code()  # Regenerate if exists
                
            # Check in laboratories
            cursor.execute("SELECT COUNT(*) FROM laboratories WHERE access_code = ?", (code,))
            if cursor.fetchone()[0] > 0:
                return self.generate_access_code()  # Regenerate if exists
                
        except sqlite3.Error:
            pass
            
        return code

if __name__ == "__main__":
    root = tk.Tk()
    app = AdminApplication(root)
    root.mainloop()