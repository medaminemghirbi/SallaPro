import subprocess
import re
import os

def install_chromedriver(version, install_path):
    # Ensure the directory exists
    os.makedirs(install_path, exist_ok=True)
    
    # Commands to install Selenium, wget, and unzip, and download the specific ChromeDriver
    commands = [
        'pip3 install selenium beautifulsoup4 pandas',
        'sudo apt-get update',
        'sudo apt install -y wget unzip',
        f'wget -q -O /tmp/chromedriver.zip https://storage.googleapis.com/chrome-for-testing-public/{version}/linux64/chromedriver-linux64.zip',
        f'unzip /tmp/chromedriver.zip -d {install_path}'
    ]
    
    for command in commands:
        print(f'Running command: {command}')
        subprocess.run(command, shell=True, check=True)

def get_chrome_version():
    # Define the command to get Google Chrome version
    command = 'google-chrome --version'
    
    # Execute the command
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    
    # Extract the version number using regex
    output = result.stdout.strip()
    match = re.search(r'(\d+\.\d+\.\d+\.\d+)', output)
    
    if match:
        return match.group(1)
    else:
        raise ValueError("Version number not found")

if __name__ == "__main__":
    try:
        chrome_version = get_chrome_version()
        print(f'Google Chrome Version: {chrome_version}')
        
        # Set the installation path to app/services/
        install_path = 'app/services/'
        install_chromedriver(chrome_version, install_path)
        print(f'ChromeDriver has been installed and set up successfully in {install_path}.')
    except Exception as e:
        print(f'An error occurred: {e}')
