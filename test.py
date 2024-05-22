from PIL import Image, ImageDraw
import io
import base64
import pyodbc

def sqlConnect():
    """
    Connects to a SQL Server database.

    Returns:
        tuple: A tuple containing a cursor object and a connection object if the connection is successful, otherwise dict().
    """
    try:
        #server info 
        server = 'hpcs.database.windows.net'
        database = 'hpdb'
        username = 'hpUser'
        password = '0153HP!!'
        driver = '{ODBC Driver 18 for SQL Server}'
        # Establish the connection
        conn_str = f'DRIVER={driver};SERVER={server};DATABASE={database};UID={username};PWD={password};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;'
        conn = pyodbc.connect(conn_str)
        # Create a cursor object to interact with the database
        cursor = conn.cursor()
        return cursor, conn
    except pyodbc.Error as e:
        print(f"Error: {e}")
        return None ,None
    

# Image size and circle parameters
image_size = (100, 100)  # Width, Height
circle_center = (50, 50)  # Center of the circle
circle_radius = 40  # Radius of the circle

# Create a new image with a white background
image = Image.new("L", image_size, color=255)
draw = ImageDraw.Draw(image)

# Draw a black circle on the white background
draw.ellipse([(circle_center[0] - circle_radius, circle_center[1] - circle_radius),
              (circle_center[0] + circle_radius, circle_center[1] + circle_radius)],
             fill=0)

# Get the binary pixel data of the image
binary_data = image.tobytes()

# Create an image from the binary data
img = Image.frombytes("L", image_size, binary_data)

# Show the image
img.show()

# Read the contents of the text file
with open('pdftext.txt', 'rb') as file:
    pdf_text = file.read()

# Convert text data to binary (if necessary)
# Note: If the text file already contains binary data, you can skip this step

cursor, conn = sqlConnect()


query = "INSERT INTO reciepts (image) VALUES (?)"
cursor.execute(query, (pdf_text,))  # No need to encode


conn.commit()


# Execute a query to fetch the binary data from the database
cursor.execute("SELECT TOP 1 image FROM reciepts")  # Assuming you want to retrieve the first record

# Fetch the binary data
row = cursor.fetchone()
binary_data = row[0]

# Save the binary data to a PDF file
with open('output.pdf', 'wb') as f:
    f.write(binary_data)

# Close cursor and connection
cursor.close()
conn.close()