#!/usr/bin/env python3
"""
APOD Downloader - Download NASA's Astronomy Picture of the Day
"""

import os
import sys
import re
from datetime import datetime
from pathlib import Path
from urllib.parse import urljoin

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print("Error: Required packages not installed.")
    print("Please run: pip install requests beautifulsoup4")
    sys.exit(1)

# Configuration
APOD_URL = "https://apod.nasa.gov/apod/astropix.html"
SAVE_DIR = Path.home() / "Desktop" / "APOD"


def fetch_apod_page():
    """Fetch the APOD webpage."""
    try:
        response = requests.get(APOD_URL, timeout=10)
        response.raise_for_status()
        return response.text
    except requests.RequestException as e:
        print(f"Error fetching APOD page: {e}")
        sys.exit(1)


def parse_apod_page(html):
    """Parse the APOD page to extract metadata and image URL."""
    soup = BeautifulSoup(html, 'html.parser')

    # Extract date
    date_str = None
    date_pattern = re.compile(r'(\d{4})\s+(\w+)\s+(\d{1,2})')
    center_tags = soup.find_all('center')
    for center in center_tags:
        text = center.get_text()
        match = date_pattern.search(text)
        if match:
            year, month, day = match.groups()
            # Convert month name to number
            date_obj = datetime.strptime(f"{year} {month} {day}", "%Y %B %d")
            date_str = date_obj.strftime("%Y-%m-%d")
            break

    if not date_str:
        date_str = datetime.now().strftime("%Y-%m-%d")

    # Extract title
    title = "Unknown"
    title_tag = soup.find('center')
    if title_tag:
        b_tag = title_tag.find('b')
        if b_tag:
            title = b_tag.get_text().strip()

    # Extract description
    description = ""
    explanation_tag = soup.find('b', string=re.compile(r'Explanation:', re.IGNORECASE))
    if explanation_tag:
        # Get the parent and find the next text
        parent = explanation_tag.parent
        description_parts = []
        for sibling in parent.next_siblings:
            if hasattr(sibling, 'get_text'):
                text = sibling.get_text().strip()
                if text:
                    description_parts.append(text)
            elif isinstance(sibling, str):
                text = sibling.strip()
                if text:
                    description_parts.append(text)
        description = ' '.join(description_parts)

    # Extract image URL
    image_url = None
    img_tag = soup.find('img')

    if img_tag:
        # Check if it's wrapped in an anchor tag (link to high-res version)
        parent_a = img_tag.find_parent('a')
        if parent_a and parent_a.get('href'):
            href = parent_a.get('href')
            # Check if this is a YouTube link (video instead of image)
            if 'youtube.com' in href or 'youtu.be' in href:
                print("Today's APOD is a video, not an image.")
                print(f"Video URL: {href}")
                sys.exit(0)
            # Get the high-resolution image URL
            image_url = urljoin(APOD_URL, href)
        elif img_tag.get('src'):
            # Fallback to the thumbnail if no link
            image_url = urljoin(APOD_URL, img_tag.get('src'))

    if not image_url:
        print("Error: Could not find image URL on the page.")
        sys.exit(1)

    return {
        'date': date_str,
        'title': title,
        'description': description,
        'image_url': image_url
    }


def download_image(image_url, save_path):
    """Download the image from the given URL."""
    try:
        response = requests.get(image_url, timeout=30, stream=True)
        response.raise_for_status()

        with open(save_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)

        return True
    except requests.RequestException as e:
        print(f"Error downloading image: {e}")
        return False


def save_metadata(metadata, save_path):
    """Save metadata to a text file."""
    try:
        with open(save_path, 'w', encoding='utf-8') as f:
            f.write(f"Date: {metadata['date']}\n")
            f.write(f"Title: {metadata['title']}\n")
            f.write(f"Image URL: {metadata['image_url']}\n")
            f.write(f"\nDescription:\n{metadata['description']}\n")
        return True
    except Exception as e:
        print(f"Error saving metadata: {e}")
        return False


def main():
    """Main function to download APOD."""
    print("Fetching latest APOD...")

    # Fetch and parse the APOD page
    html = fetch_apod_page()
    metadata = parse_apod_page(html)

    print(f"Title: {metadata['title']}")
    print(f"Date: {metadata['date']}")

    # Create save directory if it doesn't exist
    SAVE_DIR.mkdir(parents=True, exist_ok=True)

    # Determine file extension from URL
    image_ext = Path(metadata['image_url']).suffix
    if not image_ext or image_ext == '':
        image_ext = '.jpg'  # Default extension

    # Create filenames with date
    image_filename = f"APOD_{metadata['date']}{image_ext}"
    metadata_filename = f"APOD_{metadata['date']}.txt"

    image_path = SAVE_DIR / image_filename
    metadata_path = SAVE_DIR / metadata_filename

    # Download image
    print(f"Downloading image...")
    if download_image(metadata['image_url'], image_path):
        print(f"Image saved to: {image_path}")
    else:
        print("Failed to download image.")
        sys.exit(1)

    # Save metadata
    if save_metadata(metadata, metadata_path):
        print(f"Metadata saved to: {metadata_path}")
    else:
        print("Warning: Failed to save metadata.")

    print("\nDownload complete!")


if __name__ == "__main__":
    main()
