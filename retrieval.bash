#!/bin/bash

# Output final PDFs into one place
output_dir="Research_PDFs"

# Fetch PubMed records for "telomeres AND anti-aging" and store them in results.txt
esearch -db pubmed -query "telomeres AND anti-aging" -retmax 200 | \
efetch -format medline > results.txt

# Check if results.txt has content before proceeding
if [[ ! -s results.txt ]]; then
    echo "No results retrieved. Please check your query."
    exit 1
fi

# Split the results into individual files (one file per article)
csplit -z -f temp_ -b "%03d.txt" results.txt "/^PMID/" {*}

# Check if files were successfully created
if [[ ! -f temp_001.txt ]]; then
    echo "Error: No files created. Please check the splitting command."
    exit 1
fi


# Loop through the text files
for file in temp_*.txt; do
    # Extract the title from the text file (assuming "TI  -" is the title field in the Medline format)
    title=$(grep -m 1 "^TI  -" "$file" | sed 's/TI  - //g')

    # If the title is found, sanitize it for use as a filename (remove spaces and special characters)
    if [[ ! -z "$title" ]]; then
        clean_title=$(echo "$title" | sed 's/[^a-zA-Z0-9_-]/_/g')

        # Convert the text file to a PDF, using the cleaned title as the filename and setting the title metadata
        pdf_file="${output_dir}/${clean_title}.pdf"
        pandoc "$file" --pdf-engine=wkhtmltopdf --metadata title="$title" -o "$pdf_file"

        # Print conversion status
        echo "Converted $file to $pdf_file"

    else
        # If no title is found, delete the text file and notify the user
        echo "No title found in $file. Deleting the file."
        rm "$file"
        continue  # Skip to the next iteration of the loop
    fi
done

# Delete all txt files after conversion
rm temp_*.txt

echo "First 200 of specified PDFs retrieved."
