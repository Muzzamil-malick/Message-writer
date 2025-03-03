import streamlit as st
import pandas as pd
from io import StringIO

# Function to clean column names
def clean_column_names(df):
    df.columns = df.columns.str.replace("\n", " ").str.strip().str.upper()  # Remove newlines and spaces
    return df

# Function to determine prefix based on SOURCE
def get_prefix(source):
    if isinstance(source, str):
        if "GRAB" in source.upper():
            return "G-"
        elif "BMFS" in source.upper():
            return "BMFS-"
    return ""

# Function to format rows
def format_row(row):
    prefix = get_prefix(row["SOURCE"])
    lab_code = f"{prefix}{row['LABNO'].strip()}"
    id_code = row["IDCODE"].strip()
    location = f"*{row['DISTRICT'].strip()}, site= {row['SITE NAME'].strip()}*"
    collection_date = f"Collection Date: {row['DATE COLLECTION'].strip()}"
    genetic_cluster = f"Genetic Cluster: *{row['GENETIC CLUSTER'].strip()}*"
    closest_match = f"Closest Genetic Match: {row['CLOSEST GENETIC MATCH']}"

    return f"{lab_code}\n{id_code}\n{location}\n{collection_date}\n{genetic_cluster}\n{closest_match}"

# Streamlit UI
st.title("Message Writer")

st.sidebar.header("Input Data")
st.sidebar.write("Paste your **tab-delimited** data below and click 'Convert'.")

# Text area input
data_input = st.sidebar.text_area("Paste Data Here:", "", height=200, placeholder="Paste tab-delimited data here...")

# Convert button
if st.sidebar.button("Convert"):
    if data_input.strip():
        try:
            df = pd.read_csv(StringIO(data_input), sep="\t", dtype=str)

            # Clean column names
            df = clean_column_names(df)

            # Debugging: Show detected columns
            st.write("Detected Columns:", df.columns.tolist())

            # Required columns (make them uppercase for consistency)
            required_cols = ["SOURCE", "LABNO", "DISTRICT", "SITE NAME", "DATE COLLECTION", "CLOSEST GENETIC MATCH", "GENETIC CLUSTER", "IDCODE"]

            # Find missing columns
            missing_cols = [col for col in required_cols if col not in df.columns]

            if missing_cols:
                st.error(f"Error: Missing required columns: {', '.join(missing_cols)}")
            else:
                formatted_output = "\n\n".join(df.apply(format_row, axis=1))

                st.subheader("Formatted Output")
                st.text_area("", formatted_output, height=300)

                st.download_button(label="Download Output", data=formatted_output, file_name="formatted_output.txt", mime="text/plain")

                st.subheader("Debugging: Data Preview")
                st.dataframe(df)

        except Exception as e:
            st.error(f"Error processing the data: {e}")
    else:
        st.warning("No data provided. Please paste data into the text area.")
