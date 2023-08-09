import os

install_device = "/dev/sda"

os.system('loadkeys jp106')
os.system('lsblk')
os.system(f'cd {install_device}')
