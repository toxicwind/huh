# nsenter Documentation from Context7 (/util-linux/util-linux)

### Create a PID and Mount Namespace

Source: https://github.com/util-linux/util-linux/blob/master/sys-utils/unshare.1.adoc

This command creates a new PID namespace and a new mount namespace, mounting a fresh proc filesystem for the child process.

```bash
unshare --fork --pid --mount-proc readlink /proc/self
```

--------------------------------

### List Namespaces for a Specific Process

Source: https://github.com/util-linux/util-linux/blob/master/sys-utils/lsns.8.adoc

Display only the namespaces held by a specific process, identified by its PID.

```bash
lsns --task 1234
```

### NAME

Source: https://github.com/util-linux/util-linux/blob/master/sys-utils/nsenter.1.adoc

The nsenter command allows you to run a program within the namespaces of another process. Namespaces provide isolation for various system resources. You can enter the mount, UTS, IPC, network, PID, user, cgroup, or time namespaces. If no program is specified, it defaults to running the user's shell.

--------------------------------

### OPTIONS

Source: https://github.com/util-linux/util-linux/blob/master/sys-utils/nsenter.1.adoc

The `nsenter` command supports various options to specify which namespaces to enter. The `--all` option enters all namespaces of a target process. You can specify a target process using `--target PID`. Individual namespaces can be targeted using options like `--mount`, `--uts`, `--ipc`, `--net`, `--pid`, `--user`, `--cgroup`, and `--time`, each optionally accepting a file path or namespace ID to specify the target namespace.

--------------------------------

### nsenter(1)

Source: https://github.com/util-linux/util-linux/blob/master/sys-utils/nsenter.1.adoc

The -n, --net option enters the network namespace. If no argument is given, it uses the target process's network namespace. With a file or :nsid argument, it enters the specified network namespace.