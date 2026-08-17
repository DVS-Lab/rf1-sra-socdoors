import os
import glob
import pandas as pd

# -------------------------------------
# Settings
# -------------------------------------
tasks = ['doors', 'socialdoors']
base_dir = '/ZPOOL/data/projects/rf1-sra-socdoors/derivatives/fsl/EVfiles/'

# -------------------------------------
# 1️⃣ Collect EV files (exclude block/missed trial files)
# -------------------------------------
txt_files = [
    f for f in glob.glob(os.path.join(base_dir, 'sub-*', 'ses-01', '*', '*.txt'))
    if 'block' not in os.path.basename(f) and not f.endswith('_decision-missed.txt')
]

# -------------------------------------
# 2️⃣ Collect missed trial files
# -------------------------------------
missed_trial_files = [
    f for f in glob.glob(os.path.join(base_dir, 'sub-*', 'ses-01', '*', '_decision-missed.txt'))
]

# -------------------------------------
# 3️⃣ Dictionaries to store counts
# -------------------------------------
data = []
missed_trial_count_dict = {}
total_row_count_dict = {}

# -------------------------------------
# 4️⃣ Process EV files
# -------------------------------------
print("Processing EV files...")
for file_path in txt_files:
    with open(file_path, 'r') as file:
        content = file.readlines()
    
    # Correct subject extraction (one folder above ses-01)
    subject_number = os.path.basename(os.path.dirname(os.path.dirname(os.path.dirname(file_path)))).replace('sub-', '')
    
    # Task from folder
    task_name = os.path.basename(os.path.dirname(file_path))
    if task_name not in tasks:
        task_name = 'unknown'

    # Debug print
    print(f"EV File: {file_path}, Subject: {subject_number}, Task: {task_name}, Rows: {len(content)}")

    # Append to data
    row_count = len(content)
    data.append([subject_number, task_name, os.path.basename(file_path), row_count])

    # Track total rows per subject/task
    if task_name != 'unknown':
        if subject_number not in total_row_count_dict:
            total_row_count_dict[subject_number] = {}
        if task_name not in total_row_count_dict[subject_number]:
            total_row_count_dict[subject_number][task_name] = 0
        total_row_count_dict[subject_number][task_name] += row_count

# -------------------------------------
# 5️⃣ Process missed trial files
# -------------------------------------
print("\nProcessing missed trial files...")
for missed_path in missed_trial_files:
    subject_number = os.path.basename(os.path.dirname(os.path.dirname(os.path.dirname(missed_path)))).replace('sub-', '')
    task_name = os.path.basename(os.path.dirname(missed_path))
    if task_name not in tasks:
        task_name = 'unknown'

    with open(missed_path, 'r') as file:
        missed_trial_count = len(file.readlines())

    # Debug print
    print(f"Missed Trial File: {missed_path}, Subject: {subject_number}, Task: {task_name}, Missed Trials: {missed_trial_count}")

    if subject_number not in missed_trial_count_dict:
        missed_trial_count_dict[subject_number] = {}
    missed_trial_count_dict[subject_number][task_name] = missed_trial_count

# -------------------------------------
# 6️⃣ Create DataFrame from EV files
# -------------------------------------
df = pd.DataFrame(data, columns=['Subject', 'Task', 'Filename', 'RowCount'])

# Pivot so each file is a column
df_pivot = df.pivot_table(index=['Subject', 'Task'], columns='Filename', values='RowCount', fill_value=0).reset_index()

# Add missed trial counts
df_pivot['Missed_Trial_Count'] = df_pivot.apply(
    lambda row: missed_trial_count_dict.get(row['Subject'], {}).get(row['Task'], 0),
    axis=1
)

for idx, row in df_pivot.iterrows():
    subject = row['Subject']
    task = row['Task']
    missed = row['Missed_Trial_Count']
    total = total_row_count_dict.get(subject, {}).get(task, 0)
    threshold = 0.25 * total
    print(f"Subject: {subject}, Task: {task}, Missed: {missed}, Total: {total}, 25% threshold: {threshold}")


# Determine exclusion per task (>25% missed trials)
df_pivot['Exclusion'] = df_pivot.apply(
    lambda row: 'Exclude' if row['Missed_Trial_Count'] > 0.25 * total_row_count_dict.get(row['Subject'], {}).get(row['Task'], 0)
    else 'Include',
    axis=1
)

# -------------------------------------
# 7️⃣ Combine tasks per subject, add Total Trials
# -------------------------------------
df_subject_summary = df_pivot.groupby('Subject').apply(
    lambda g: pd.Series({
        'Overall_Exclusion': 'Exclude' if any(g['Exclusion'] == 'Exclude') else 'Include',
        'Tasks_Flagged': ', '.join(g.loc[g['Exclusion'] == 'Exclude', 'Task'].tolist()),
        'Total_Missed_Trials': g['Missed_Trial_Count'].sum(),
        # Sum all trial columns (all files) across tasks
        'Total_Trials': g[[c for c in g.columns if c not in ['Subject','Task','Missed_Trial_Count','Exclusion']]].sum().sum()
    })
).reset_index()


# -------------------------------------
# 8️⃣ Print simplified results
# -------------------------------------
print("\n=== Combined Subject Summary ===")
print(df_subject_summary.to_string(index=False))

print("\n=== Subjects to Include ===")
print(df_subject_summary[df_subject_summary['Overall_Exclusion']=='Include'].to_string(index=False))

print("\n=== Subjects to Exclude ===")
print(df_subject_summary[df_subject_summary['Overall_Exclusion']=='Exclude'].to_string(index=False))
