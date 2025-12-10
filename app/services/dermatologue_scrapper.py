from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from bs4 import BeautifulSoup
import pandas as pd
import os

# Options for Chrome browser
chrome_options = Options()
chrome_options.add_argument("--headless")  # Run Chrome in headless mode
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--disable-blink-features=AutomationControlled")
chrome_options.binary_location = "/usr/bin/google-chrome-stable"

# Path to ChromeDriver
chrome_service = Service('app/services/chromedriver-linux64/chromedriver')

# Initialize the WebDriver
driver = webdriver.Chrome(service=chrome_service, options=chrome_options)

# # List of governments
# gouvernements = ['ben-arous', 'bizerte', 'beja', 'gabes', 'gafsa', 'ariana',
#                  'hammamet', 'jendouba', 'kairouan', 'kasserine',
#                  'kebili', 'la-manouba', 'le-kef', 'mahdia', 'medenine',
#                  'monastir', 'nabeul', 'sfax', 'sidi-bou-zid', 'siliana',
#                  'sousse', 'tataouine', 'tozeur', 'tunis', 'zaghouan']

gouvernements = ['sousse']

specialities = ['dermatologue', 'cardiologue', 'pediatre', 'medecin-generaliste']
# Initialize an empty list to store doctor data
doctors_data = []

# Iterate over each government
for gouvernement in gouvernements:
    page_num = 1
    while True:
        url = f"https://www.dabadoc.com/tn/dermatologue/{gouvernement}/page/{page_num}"
        driver.get(url)
        html = driver.page_source
        bs = BeautifulSoup(html, 'html.parser')

        doctor_cards = bs.find_all('div', class_='search_doc_row')
        if not doctor_cards:  # If no doctor cards are found, break the loop
            break

        for card in doctor_cards:
            name_elem = card.find('h2', class_='blue-text h5 font-weight-normal')
            name = name_elem.text.strip() if name_elem else None

            # Check if the name starts with "Dr" and remove it
            if name and name.startswith('Dr'):
                name = name.replace('Dr', '').strip()

            profile_link_elem = card.find('a', class_='profile_url', href=True)
            profile_link = profile_link_elem['href'] if profile_link_elem else None

            # Ensure the profile link is properly formatted
            if profile_link and not profile_link.startswith('http'):
                profile_link = "https://www.dabadoc.com" + profile_link

            doctor_info = {
                'name': name,
                'location': gouvernement if gouvernement else "Unknown",
                'speciality': 'dermatologue',
                'gouvernement':gouvernement
            }

            # Navigate to the doctor's profile page and get additional information
            if profile_link:
                driver.get(profile_link)
                profile_html = driver.page_source
                profile_bs = BeautifulSoup(profile_html, 'html.parser')

                # Get the additional information from the doctor's profile
                card_text_elem = profile_bs.find('div', class_='card-text')
                additional_info = card_text_elem.text.strip().replace('\n', ' ') if card_text_elem else '#'
                doctor_info['description'] = additional_info

                # Get the avatar image from the doctor's profile
                avatar_elem = profile_bs.find('div', class_='col-md-3 doctor-avatar').find('img', class_='rounded-circle')
                avatar_src = avatar_elem['src'] if avatar_elem else '#'
                doctor_info['avatar_src'] = avatar_src

                # Extract phone number from the "tel" link
                phone_elem = profile_bs.find('a', class_='btn btn-block btn-primary', href=True)
                if phone_elem:
                    phone_number = phone_elem['href'].replace('tel:', '') if phone_elem else '#'
                    doctor_info['phone_number'] = phone_number

                # # Extract Google Maps location URL
                # maps_elem = profile_bs.find('a', {'href': True, 'target': 'new'})
                # if maps_elem:
                #     google_maps_url = maps_elem['href'] if maps_elem else '#'
                #     doctor_info['google_maps_url'] = google_maps_url

            doctors_data.append(doctor_info)

        page_num += 1

driver.quit()  # Close the browser

# Convert to DataFrame
df = pd.DataFrame(doctors_data)

# Path to save the CSV file
csv_file_path = os.path.join(os.path.dirname(__file__), 'dermatologue_doctors.csv')

# Check if the file exists and delete it if necessary
if os.path.exists(csv_file_path):
    os.remove(csv_file_path)

# Save the DataFrame to the CSV file
df.to_csv(csv_file_path, index=False)
print(f"Data saved to {csv_file_path}")
