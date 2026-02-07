# Ansible Learning Demo: WordPress Deployment

Welcome! In this hands-on lab, you'll learn Ansible by deploying a real WordPress website across 3 servers.

## What We're Building

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Web Server    │     │ WordPress Server│     │ Database Server │
│    (Nginx)      │ --> │   (PHP + WP)    │ --> │    (MySQL)      │
│  fffics-srv-4   │     │  fffics-srv-3   │     │  fffics-srv-2   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Prerequisites

- VS Code installed on your computer
- Access to your 3 lab servers (IPs provided by Openstack as a floating ip)

---

## Session 1: Getting Started + MySQL

### Step 1: Open the Project in VS Code

1. Open VS Code
2. Go to **File → Open Folder**
3. Navigate to this folder and click **Open**

### Step 2: Update Your Server IPs

Open `inventory.ini` and update the IP addresses to match YOUR servers:

```ini
[webserver]
fffics-srv-4 ansible_host=YOUR_WEBSERVER_IP

[wordpress]
fffics-srv-3 ansible_host=YOUR_WORDPRESS_IP

[database]
fffics-srv-2 ansible_host=YOUR_DATABASE_IP
```

### Step 3: Set Up SSH Keys

Open a terminal in VS Code (**Terminal → New Terminal**) and run:

```bash
./setup-ssh.sh
```

This will:
- Generate an SSH key (if you don't have one)
- Copy your key to all 3 servers
- Test the connections

### Step 4: Test Ansible Connection

Run this command to verify Ansible can reach all servers:

```bash
ansible all -m ping
```

You should see green "SUCCESS" messages for all 3 servers!

### Step 5: Complete the MySQL Role

Open `roles/mysql/tasks/main.yml` in VS Code.

You'll see comment blocks explaining each task and `STUDENT TODO` markers where you need to write code.

**Tasks to complete:**
1. Install MySQL server package
2. Start and enable MySQL service
3. Set the root password
4. Create the WordPress database
5. Create the WordPress user

### Step 6: Run the MySQL Playbook

```bash
ansible-playbook playbook.yml --tags mysql
```

### Step 7: Verify MySQL is Working

```bash
ansible database -m shell -a "mysql -u root -pStudentDemo123! -e 'SHOW DATABASES;'"
```

You should see the `wordpress` database listed!

---

## Session 2: WordPress + Nginx

### Step 8: Complete the WordPress Role

Open `roles/wordpress/tasks/main.yml`

**Tasks to complete:**
1. Install PHP and extensions
2. Download WordPress
3. Extract WordPress files
4. Configure wp-config.php using template
5. Set file ownership

### Step 9: Run the WordPress Playbook

```bash
ansible-playbook playbook.yml --tags wordpress
```

### Step 10: Complete the Nginx Role

Open `roles/nginx/tasks/main.yml`

**Tasks to complete:**
1. Install Nginx
2. Deploy site configuration
3. Enable the WordPress site
4. Start Nginx service

### Step 11: Run the Full Playbook

```bash
ansible-playbook playbook.yml
```

### Step 12: Test Your Website!

Open a browser and go to:

```
http://YOUR_WEBSERVER_IP
```

You should see the WordPress setup wizard!

---

## Command Cheat Sheet

| Command | What it does |
|---------|--------------|
| `ansible all -m ping` | Test connection to all servers |
| `ansible-playbook playbook.yml` | Run the full playbook |
| `ansible-playbook playbook.yml --tags mysql` | Run only MySQL tasks |
| `ansible-playbook playbook.yml --check` | Dry run (show what would change) |
| `ansible database -m shell -a "command"` | Run a command on database server |

## Troubleshooting

### "Permission denied" errors
- Make sure you ran `./setup-ssh.sh` first
- Check that your SSH key was copied successfully

### YAML syntax errors
- Check your indentation (use spaces, not tabs!)
- Make sure colons have a space after them: `name: value`
- Variables need quotes: `"{{ variable_name }}"`

### Can't connect to servers
- Verify your IP addresses in `inventory.ini`
- Make sure you're connected to the CyberRange network

---

## VS Code Tips for YAML

- **Indentation matters!** Use 2 spaces (VS Code should do this automatically)
- Install the "YAML" extension for better syntax highlighting
- If you see red squiggly lines, check your indentation

## Connecting to Servers via VS Code (Optional)

You can connect directly to your servers using VS Code Remote SSH:

1. Install the "Remote - SSH" extension in VS Code
2. Press `F1` and type "Remote-SSH: Connect to Host"
3. Enter: `cyberrange@YOUR_SERVER_IP`
4. When prompted about jump host, VS Code will use your SSH config

---

## What You Learned

- **Inventory files** - How to define servers and groups
- **Playbooks** - How to organize tasks into plays
- **Roles** - How to structure reusable automation
- **Modules** - apt, service, file, template, mysql_user, mysql_db
- **Variables** - How to use and reference variables
- **Templates** - How to generate config files with Jinja2

Congratulations! You've deployed a multi-tier web application with Ansible!
