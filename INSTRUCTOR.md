# Instructor Guide: Ansible Learning Demo

## Overview

This guide helps you facilitate the 2-session Ansible workshop. Each session is 1 hour.

---

## Pre-Class Setup

### Verify Student VMs are Running
Each student needs 3 Ubuntu Noble servers. Verify they're accessible:
```bash
# Test from your machine (update IPs)
ssh -J sshjump@ssh.cyberrange.rit.edu cyberrange@100.65.X.X
```

### Install sshpass on Student Machines (if needed)
The setup script needs `sshpass` to copy SSH keys:
```bash
sudo apt-get install sshpass
```

### Test the Full Deployment
Run through the complete playbook on a test set of VMs to catch any issues:
```bash
# Copy solutions to roles for testing
cp solutions/mysql-tasks.yml roles/mysql/tasks/main.yml
cp solutions/wordpress-tasks.yml roles/wordpress/tasks/main.yml
cp solutions/nginx-tasks.yml roles/nginx/tasks/main.yml
ansible-playbook playbook.yml
```

---

## Session 1 Timeline (1 hour)

| Time | Duration | Activity |
|------|----------|----------|
| 0:00 | 5 min | Introduction: What is Ansible? Why automation? |
| 0:05 | 5 min | SSH setup: Have students run `./setup-ssh.sh` |
| 0:10 | 10 min | Explain inventory.ini - groups, variables, connection settings |
| 0:20 | 5 min | First Ansible command: `ansible all -m ping` |
| 0:25 | 5 min | Walk through playbook.yml structure |
| 0:30 | 25 min | **Students complete MySQL role tasks** |
| 0:55 | 5 min | Run playbook, verify database exists |

### Key Teaching Points - Session 1

**What is Ansible?**
- Agentless - no software to install on servers
- Uses SSH - same way you'd connect manually
- Idempotent - safe to run multiple times
- YAML - human-readable configuration

**Inventory Concepts**
- Groups organize servers by function
- `all:vars` applies to every server
- Jump host configured in `ansible_ssh_common_args`

**Module Pattern**
Every module follows: `module_name: parameter: value`
```yaml
- name: Description of what this does
  apt:
    name: mysql-server
    state: present
```

---

## Session 1 Solutions

### MySQL Task 1: Install MySQL server
```yaml
- name: Install MySQL server
  apt:
    name: mysql-server
    state: present
    update_cache: yes
```

### MySQL Task 3: Start and enable service
```yaml
- name: Start and enable MySQL service
  service:
    name: mysql
    state: started
    enabled: yes
```

### MySQL Task 4: Set root password
```yaml
- name: Set MySQL root password
  mysql_user:
    name: root
    password: "{{ mysql_root_password }}"
    login_unix_socket: /var/run/mysqld/mysqld.sock
    state: present
```

### MySQL Task 5: Create database
```yaml
- name: Create WordPress database
  mysql_db:
    name: "{{ wordpress_db_name }}"
    state: present
    login_user: root
    login_password: "{{ mysql_root_password }}"
    login_unix_socket: /var/run/mysqld/mysqld.sock
```

### MySQL Task 6: Create user
```yaml
- name: Create WordPress database user
  mysql_user:
    name: "{{ wordpress_db_user }}"
    password: "{{ wordpress_db_password }}"
    priv: "{{ wordpress_db_name }}.*:ALL"
    host: "{{ wordpress_server }}"
    state: present
    login_user: root
    login_password: "{{ mysql_root_password }}"
    login_unix_socket: /var/run/mysqld/mysqld.sock
```

---

## Session 2 Timeline (1 hour)

| Time | Duration | Activity |
|------|----------|----------|
| 0:00 | 5 min | Review: Verify MySQL from Session 1 is still running |
| 0:05 | 5 min | Explain templates and Jinja2 basics |
| 0:10 | 20 min | **Students complete WordPress role tasks** |
| 0:30 | 5 min | Run WordPress playbook, discuss results |
| 0:35 | 15 min | **Students complete Nginx role tasks** |
| 0:50 | 10 min | Full deployment, test in browser, wrap-up |

### Key Teaching Points - Session 2

**Templates**
- `.j2` files are Jinja2 templates
- `{{ variable }}` gets replaced with actual values
- Show `wp-config.php.j2` - point out the database variables

**Why Reverse Proxy?**
- Performance: Nginx handles static files efficiently
- Security: WordPress isn't directly exposed
- Flexibility: Easy to add caching, SSL, multiple backends

---

## Session 2 Solutions

### WordPress Task 1: Install PHP
```yaml
- name: Install PHP and extensions
  apt:
    name: "{{ php_packages }}"
    state: present
    update_cache: yes
```

### WordPress Task 3: Download WordPress
```yaml
- name: Download WordPress
  get_url:
    url: "{{ wordpress_download_url }}"
    dest: /tmp/wordpress.tar.gz
```

### WordPress Task 4: Extract WordPress
```yaml
- name: Extract WordPress
  unarchive:
    src: /tmp/wordpress.tar.gz
    dest: "{{ wordpress_install_dir }}"
    remote_src: yes
    extra_opts: ["--strip-components=1"]
```

### WordPress Task 5: Configure WordPress
```yaml
- name: Configure WordPress
  template:
    src: wp-config.php.j2
    dest: "{{ wordpress_install_dir }}/wp-config.php"
    owner: www-data
    group: www-data
```

### WordPress Task 6: Set ownership
```yaml
- name: Set WordPress file ownership
  file:
    path: "{{ wordpress_install_dir }}"
    owner: www-data
    group: www-data
    recurse: yes
```

### Nginx Task 1: Install Nginx
```yaml
- name: Install Nginx
  apt:
    name: nginx
    state: present
    update_cache: yes
```

### Nginx Task 2: Deploy config
```yaml
- name: Deploy Nginx site configuration
  template:
    src: wordpress.conf.j2
    dest: /etc/nginx/sites-available/wordpress
  notify: Restart Nginx
```

### Nginx Task 3: Enable site
```yaml
- name: Enable WordPress site
  file:
    src: /etc/nginx/sites-available/wordpress
    dest: /etc/nginx/sites-enabled/wordpress
    state: link
  notify: Restart Nginx
```

### Nginx Task 5: Start service
```yaml
- name: Ensure Nginx is running
  service:
    name: nginx
    state: started
    enabled: yes
```

---

## Common Student Mistakes

### 1. Indentation Errors
**Problem:** YAML is whitespace-sensitive
```yaml
# WRONG - inconsistent indentation
- name: Install MySQL
apt:
  name: mysql-server
```
```yaml
# CORRECT
- name: Install MySQL
  apt:
    name: mysql-server
```

**Fix:** Have them check that module name aligns under the hyphen, and parameters are indented under the module.

### 2. Missing Quotes Around Variables
**Problem:** Special characters in variables
```yaml
# WRONG - will fail
password: {{ mysql_root_password }}
```
```yaml
# CORRECT
password: "{{ mysql_root_password }}"
```

**Fix:** Always wrap `{{ }}` in double quotes.

### 3. Tabs Instead of Spaces
**Problem:** YAML doesn't allow tabs
**Fix:** Have VS Code convert tabs to spaces (look at bottom status bar)

### 4. Forgetting `state: present`
**Problem:** Module doesn't do anything without state
**Fix:** Remind them that `state` tells Ansible what to do (install, remove, start, etc.)

---

## Discussion Prompts

1. **"Why didn't we have to SSH into each server manually?"**
   - Ansible manages connections for us
   - Inventory tells it where servers are
   - Playbook tells it what to do

2. **"What if we had 100 servers instead of 3?"**
   - Same playbook, just add servers to inventory
   - Ansible runs in parallel

3. **"What happens if we run the playbook twice?"**
   - Idempotency - only makes changes if needed
   - "Changed" vs "Ok" in output

4. **"How would we add HTTPS?"**
   - Add certbot role
   - Update nginx template
   - Same pattern they just learned

---

## Extension Ideas (Fast Students)

1. **Add a health check task** - Use `uri` module to verify WordPress responds
2. **Add a backup task** - Use `mysql_db` with `state: dump`
3. **Parameterize the site** - Make site title a variable, run with `--extra-vars`

---

## Quick Commands Reference

```bash
# Test connections
ansible all -m ping

# Run full playbook
ansible-playbook playbook.yml

# Run specific role
ansible-playbook playbook.yml --tags mysql

# Check mode (dry run)
ansible-playbook playbook.yml --check

# Verbose output
ansible-playbook playbook.yml -vvv

# Run command on specific group
ansible database -m shell -a "systemctl status mysql"

# Check MySQL database
ansible database -m shell -a "mysql -u root -pStudentDemo123! -e 'SHOW DATABASES;'"
```

---

## Fallback: If Things Go Wrong

### Reset MySQL Server
```bash
ansible database -m shell -a "apt-get purge -y mysql-server mysql-client && rm -rf /var/lib/mysql"
```

### Reset WordPress Server
```bash
ansible wordpress -m shell -a "rm -rf /var/www/wordpress && apt-get purge -y php*"
```

### Reset Nginx Server
```bash
ansible webserver -m shell -a "apt-get purge -y nginx && rm -rf /etc/nginx"
```

### Copy Solutions (Emergency)
If time runs out:
```bash
cp solutions/mysql-tasks.yml roles/mysql/tasks/main.yml
cp solutions/wordpress-tasks.yml roles/wordpress/tasks/main.yml
cp solutions/nginx-tasks.yml roles/nginx/tasks/main.yml
ansible-playbook playbook.yml
```
