import os

install_device = "/dev/sda"

os.system('loadkeys jp106')
os.system(f'fdisk {install_device}')

import SendKeys
SendKeys.SendKeys('o')

#os.system('o')

#os.system('n')
#os.system('p')
#os.system('1')
#os.system('')
#os.system('+512M')
