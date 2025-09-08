# PATCH SUGGESTION (quote & /bin/sh -c):
import shlex, subprocess
cmd = "cmd1 ARG | cmd2"  # build with shlex.quote(user_input) for variables!
safe = "/bin/sh -c " + shlex.quote(cmd)
subprocess.run(["/bin/sh","-c", cmd], check=True)
# or better: subprocess.run(["cmd1", arg, ...], check=True)
