# Ansible Learning Demo Design

## Overview

A two-session hands-on Ansible workshop for students inexperienced with Linux CLI and sysadmin. Students deploy a 3-tier WordPress stack across 3 Ubuntu servers by writing portions of Ansible playbooks themselves.

## Target Audience

- Inexperienced with Linux command line
- New to Ansible and system administration
- Using VS Code for editing

## Infrastructure

Each student has 3 Ubuntu Noble servers:

| Role | Hostname | IP (example) | Purpose |
|------|----------|--------------|---------|
| Database | fffics-srv-2 | 100.65.6.146 | MySQL server |
| Application | fffics-srv-3 | 100.65.4.183 | WordPress + PHP |
| Web | fffics-srv-4 | 100.65.5.241 | Nginx reverse proxy |

**Credentials**: cyberrange / Cyberrange123!

**SSH Access**: Via jump host `sshjump@ssh.cyberrange.rit.edu` (no auth required on jump host)

## Session Structure

### Session 1 (1 hour): Foundations + Database

| Time | Activity |
|------|----------|
| 5 min | SSH key setup (run setup-ssh.sh) |
| 15 min | Understand inventory, test connectivity with `ansible all -m ping` |
| 10 min | Learn playbook structure with simple example |
| 25 min | **Student exercise**: Write MySQL installation tasks |
| 5 min | Verify MySQL is working |

### Session 2 (1 hour): Application + Web Tier

| Time | Activity |
|------|----------|
| 5 min | Review, verify MySQL still running |
| 25 min | **Student exercise**: Write WordPress installation tasks |
| 20 min | **Student exercise**: Write Nginx reverse proxy tasks |
| 10 min | Final deployment and browser testing |

## Project Structure

```
cdt-ansible-demo-1/
├── README.md                    # Student-facing instructions
├── INSTRUCTOR.md                # Solutions + teaching notes
├── setup-ssh.sh                 # One-command SSH setup
├── inventory.ini
├── ansible.cfg
├── playbook.yml
├── group_vars/
│   └── all.yml
├── roles/
│   ├── mysql/
│   │   └── tasks/main.yml       # Scaffolded for students
│   ├── wordpress/
│   │   ├── tasks/main.yml       # Scaffolded for students
│   │   └── templates/
│   │       └── wp-config.php.j2
│   └── nginx/
│       ├── tasks/main.yml       # Scaffolded for students
│       └── templates/
│           └── wordpress.conf.j2
└── solutions/                   # Complete working versions
    ├── mysql-tasks.yml
    ├── wordpress-tasks.yml
    └── nginx-tasks.yml
```

## Student Exercise Structure

Each role's `tasks/main.yml` contains:
- Comment blocks explaining what needs to happen
- Empty task skeletons with `name:` pre-written
- `# STUDENT TODO` markers where they write 2-4 lines
- Hints referencing the correct Ansible module

### MySQL Role Tasks (Session 1)

| Task | Module | Lines | Concept |
|------|--------|-------|---------|
| Install MySQL server | apt | 2 | Package management |
| Start MySQL service | service | 3 | Service management |
| Set root password | mysql_user | 4 | Idempotency |
| Create WordPress database | mysql_db | 2 | Database provisioning |
| Create WordPress user | mysql_user | 5 | User/permissions |

### WordPress Role Tasks (Session 2)

| Task | Module | Lines | Concept |
|------|--------|-------|---------|
| Install PHP and dependencies | apt (list) | 3 | Multiple packages |
| Download WordPress | get_url | 3 | Fetching remote files |
| Extract WordPress | unarchive | 3 | Archive handling |
| Configure wp-config.php | template | 3 | Jinja2 templates |
| Set file ownership | file | 3 | Permissions |

### Nginx Role Tasks (Session 2)

| Task | Module | Lines | Concept |
|------|--------|-------|---------|
| Install Nginx | apt | 2 | Review |
| Deploy site config | template | 3 | Templates |
| Enable site | file (link) | 3 | Symbolic links |
| Restart Nginx | service | 2 | Handlers |

## Variables (group_vars/all.yml)

```yaml
# Database Configuration
mysql_root_password: "StudentDemo123!"
wordpress_db_name: "wordpress"
wordpress_db_user: "wp_user"
wordpress_db_password: "WPDemo456!"

# WordPress Configuration
wordpress_site_title: "My Ansible Demo Site"

# Server References
database_server: "{{ hostvars['fffics-srv-2']['ansible_host'] }}"
wordpress_server: "{{ hostvars['fffics-srv-3']['ansible_host'] }}"
webserver_ip: "{{ hostvars['fffics-srv-4']['ansible_host'] }}"
```

## SSH Configuration

### Jump Host Setup

All connections go through `sshjump@ssh.cyberrange.rit.edu` (no auth required).

### inventory.ini

```ini
[webserver]
fffics-srv-4 ansible_host=100.65.5.241

[wordpress]
fffics-srv-3 ansible_host=100.65.4.183

[database]
fffics-srv-2 ansible_host=100.65.6.146

[all:vars]
ansible_user=cyberrange
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o ProxyJump=sshjump@ssh.cyberrange.rit.edu'
```

### VS Code Remote SSH Config (~/.ssh/config)

```
Host ssh.cyberrange.rit.edu
    User sshjump

Host fffics-srv-*
    User cyberrange
    ProxyJump sshjump@ssh.cyberrange.rit.edu

Host 100.65.*
    User cyberrange
    ProxyJump sshjump@ssh.cyberrange.rit.edu
```

## Instructor Materials

INSTRUCTOR.md includes:
- Step-by-step facilitation guide with timing
- Complete solutions for each task
- Common errors and fixes (YAML indentation, missing quotes, etc.)
- Discussion prompts
- Extension ideas for fast students

## Success Criteria

- Students can run `ansible all -m ping` and see green responses
- Session 1 ends with MySQL running and WordPress database created
- Session 2 ends with WordPress accessible in browser at webserver IP
- Students understand: inventory, playbooks, modules, variables, templates
