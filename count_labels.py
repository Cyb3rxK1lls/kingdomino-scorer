import os

count = 0
values = [0] * 16
with open("classes.txt") as file:
    labels = file.read().split('\n')
    labels.remove('')

main_path = os.path.join("pictures", "labels")
for folder in ["train", "test", "val"]:
    for name in os.listdir(os.path.join(main_path, folder)):
        if name.split('.')[1] != "txt" or name == "classes.txt":
            continue
        with open(os.path.join(main_path, folder, name)) as file:
            lines = file.read().split("\n")
            for line in lines:
                count += 1
                if line != '':
                    values[int(line.split(' ')[0])] += 1

for i in range(len(labels)):
    print(labels[i] + ":", values[i])
print("total:", count)
