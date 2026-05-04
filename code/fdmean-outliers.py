import os
import glob
import pandas as pd
import numpy as np

# Path to the TSV files
path = "/ZPOOL/data/projects/rf1-sra-linux2/derivatives/fmriprep-24/sub-*/ses-01/func/*doors*_desc-confounds_timeseries.tsv"

# Find all TSV files
tsv_files = glob.glob(path)

print(f"Found {len(tsv_files)} files\n")

# Dictionary to store participant IDs and their respective tasks' FD values
participant_fd = {}

for file in tsv_files:
    # Extract the participant ID and task from the file name
    file_name = os.path.basename(file)
    parts = file_name.split('_')
    
    # Extract participant ID (sub-XXXXX)
    participant_id = parts[0].replace('sub-', '')
    
    # Extract task - find the part that contains 'task-'
    task = None
    for part in parts:
        if 'task-' in part:
            task = part.replace('task-', '')
            break
    
    if task is None:
        print(f"Could not find task in {file_name}")
        continue

    # Read the TSV file using pandas
    try:
        df = pd.read_csv(file, delimiter='\t')

        # Extract framewise_displacement column and calculate mean (skip NaN values)
        avg_fd = df['framewise_displacement'].mean()

        # Store the value in participant_fd dictionary
        if participant_id not in participant_fd:
            participant_fd[participant_id] = {}

        participant_fd[participant_id][task] = avg_fd

    except (pd.errors.EmptyDataError, KeyError, IndexError) as e:
        print(f"Error processing file {file}: {str(e)}")

# Collect all FD values for outlier detection
all_fd_values = []
for participant_id, tasks in participant_fd.items():
    for task, fd_value in tasks.items():
        if not np.isnan(fd_value):
            all_fd_values.append(fd_value)

# Calculate outlier thresholds using IQR method
q1 = np.percentile(all_fd_values, 25)
q3 = np.percentile(all_fd_values, 75)
iqr = q3 - q1
lower_bound = q1 - 1.5 * iqr
upper_bound = q3 + 1.5 * iqr

print(f"Outlier Detection (IQR Method):")
print(f"Q1: {q1:.6f}, Q3: {q3:.6f}, IQR: {iqr:.6f}")
print(f"Lower bound: {lower_bound:.6f}, Upper bound: {upper_bound:.6f}\n")

# Print the results in tabular format with outlier identification
print("Participant ID\tTask\t\tFD Mean\t\tOutlier")
print("---------------------------------------------------------------")
for participant_id in sorted(participant_fd.keys()):
    tasks = participant_fd[participant_id]
    for task in sorted(tasks.keys()):
        fd_value = tasks[task]
        is_outlier = "YES" if (fd_value < lower_bound or fd_value > upper_bound) else "NO"
        print(f"{participant_id}\t\t{task}\t\t{fd_value:.6f}\t{is_outlier}")

# Summary of outliers
print("\n" + "="*70)
print("OUTLIER SUMMARY")
print("="*70)

outlier_subjects = set()
for participant_id in sorted(participant_fd.keys()):
    tasks = participant_fd[participant_id]
    for task, fd_value in tasks.items():
        if fd_value < lower_bound or fd_value > upper_bound:
            outlier_subjects.add(participant_id)

for participant_id in sorted(outlier_subjects):
    print(participant_id)

print(f"\nTotal outlier subjects: {len(outlier_subjects)}")

# Save results to TSV file
output_data = []
for participant_id in sorted(participant_fd.keys()):
    tasks = participant_fd[participant_id]
    for task in sorted(tasks.keys()):
        fd_value = tasks[task]
        is_outlier = (fd_value < lower_bound or fd_value > upper_bound)
        output_data.append({
            'participant_id': participant_id,
            'task': task,
            'fd_mean': fd_value,
            'outlier': is_outlier
        })

output_df = pd.DataFrame(output_data)
n_subjects = len(participant_fd)
output_filename = f"socialdoors-mriqc-n{n_subjects}.tsv"
output_df.to_csv(output_filename, sep='\t', index=False)
print(f"\nResults saved to: {output_filename}")
