##  bash_profile

The `.bash_profile` is a script that runs automatically when a user logs into a terminal session. You can add `export` commands in the `.bash_profile` to set environment variables, paths, and other configurations.

Here’s an example of a basic `.bash_profile` script that includes commonly exported items such as `PATH`, Oracle environment variables, and any custom environment settings you might need:

### Sample `.bash_profile` Script:

```bash
# ~/.bash_profile

# Set the PATH variable (this adds custom directories to your system path)
export PATH=$PATH:$HOME/bin:/usr/local/bin

# Oracle Environment Variables (modify the paths according to your Oracle installation)
export ORACLE_HOME=/path/to/oracle/home
export ORACLE_SID=your_sid
export PATH=$ORACLE_HOME/bin:$PATH

# JAVA Environment Variables (if you're using Java)
export JAVA_HOME=/usr/lib/jvm/java-version
export PATH=$JAVA_HOME/bin:$PATH

# PostgreSQL Environment Variables (if you're using PostgreSQL)
export PGDATA=/var/lib/pgsql/data
export PATH=/usr/pgsql-13/bin:$PATH

# MySQL Environment Variables (if you're using MySQL)
export MYSQL_HOME=/usr/local/mysql
export PATH=$MYSQL_HOME/bin:$PATH

# Python Environment Variables (if you're using Python)
export PYTHON_HOME=/usr/local/python
export PATH=$PYTHON_HOME/bin:$PATH

# Set custom aliases (optional, for ease of use)
alias ll='ls -alF'
alias gs='git status'

# Export your preferred editor
export EDITOR=nano

# Set any additional environment variables or paths here

# Load .bashrc if it exists
if [ -f ~/.bashrc ]; then
   . ~/.bashrc
fi
```

### Explanation:
1. **PATH**: Adds custom directories (like `bin` folders) to the existing `$PATH`. This is where executables are searched for by the shell.
2. **Oracle Environment Variables**: If you're using Oracle SQL*Plus or other Oracle tools, you'll need to set the `ORACLE_HOME` (where Oracle is installed) and `ORACLE_SID` (the Oracle System ID).
3. **Java, PostgreSQL, MySQL, Python**: If you're working with these, you should set the respective home directories and add them to your `PATH`.
4. **Aliases**: Optional shortcuts like `ll` for `ls -alF` or `gs` for `git status` to make commands easier to use.
5. **EDITOR**: Sets the default text editor (e.g., `nano` or `vim`).

### How to apply changes:
After editing your `.bash_profile`, run this command to apply the changes:
```bash
source ~/.bash_profile
```

This will export all the defined variables and paths for the current session.

<hr>

Here is the `.bash_profile` script from the image you shared:

```bash
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# User specific environment and startup programs
PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH

# Oracle Settings
export TMP=/tmp
export TMPDIR=$TMP

export ORACLE_BASE=/u01/app/oracle
export DB_HOME=$ORACLE_BASE/product/19.0.0/db_1
export ORACLE_HOME=$DB_HOME
export ORACLE_SID=prod
export ORACLE_TERM=xterm

export BASE_PATH=/usr/sbin:/usr/bin
export PATH=$ORACLE_HOME/bin:$BASE_PATH:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
```

### Explanation:
- **ORACLE Settings**: The script sets the environment for Oracle:
  - `ORACLE_BASE` is where Oracle software is located.
  - `ORACLE_HOME` points to the Oracle database home directory.
  - `ORACLE_SID` is the Oracle system ID (here it is `prod`).
  - `LD_LIBRARY_PATH` ensures that Oracle's libraries can be found by the system.
  - `CLASSPATH` includes the Java runtime and other Oracle-related Java libraries.

- **Path settings**: It adds Oracle's binary directory to the `PATH`, ensuring the system can find Oracle tools like `sqlplus`.

- **TMP/TMPDIR**: These environment variables point to temporary directories.

Let me know if you need further clarification or modifications!
