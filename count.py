import os
import glob
import re

total_tokens = 0

# Replace /path/to/directory with the directory containing the .lua files
for filename in glob.glob('./ggos/*.*'):
    with open(filename, 'r') as file:
        content = file.read()
        # Remove comments and whitespace to get only the code
        code = ''.join([c for c in content if c not in ['\n', '\r', '\t', ' ']])
        code = re.sub('--.*?\n', '', code)
        # Count the number of tokens
        num_tokens = len(code)
        # Update the total number of tokens
        total_tokens += num_tokens

print(f'Total number of tokens: {total_tokens}')
