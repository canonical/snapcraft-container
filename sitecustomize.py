import subprocess
import os

os.environ["QEMU_CPU"] = "max"

og_popen = subprocess.Popen


class WrapPopen(og_popen):
    def __init__(self, *args, **kwargs):
        if "env" in kwargs and kwargs["env"] is not None:
            kwargs["env"]["QEMU_CPU"] = "max"
        super().__init__(*args, **kwargs)


subprocess.Popen = WrapPopen
