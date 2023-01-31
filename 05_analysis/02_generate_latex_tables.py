import os
import shutil
import statistics
from collections import Counter

import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from matplotlib.offsetbox import AnchoredText
from matplotlib.ticker import MaxNLocator


dataLocation = '../04_data'
data = pd.read_csv('{}/questionnaire_data.csv'.format(dataLocation), sep=';')

outputLocation = '../06_output/tables'

if os.path.exists(outputLocation):
    shutil.rmtree(outputLocation)
if not os.path.exists(outputLocation):
    os.makedirs(outputLocation)

dimensions = ['Model management', 'Collaboration', 'Communication']
    
colnames = {
    'Model management': [
        [
            'Collaboration at model level', 
            'Collaboration at metamodel level',
            'Multi-view modeling',
            'General-purpose modeling languages',
            'Domain-specific modeling languages',
            'Importing external languages into the modeling environment'
        ],
        [
            "Model validation",
            "Model execution",
            "Model debugging",
            "Model browsing/search",
            "Model testing",
            "Lazy loading of the models/workspace",
            "Round-trip engineering",
            "Code generation",
            "Model transformations",
            "Integration with build/DevOps",
            "Database integration",
            "Metrics of model complexity",
            "Natural Language Processing"],
        [
            "Visual editors",
            "Textual editors",
            "Tabular editors",
            "Tree-based editors",
            "Sketch-based editors",
            "Editors w/ multiple notations",
            "Projectional editing",
            "Desktop-based environment",
            "Web-based environment",
            "Mobile environment"]],
    'Collaboration' : [
        [
            "RBAC",
            "Auth from corporate DB",
            "Anonymous access",
            "User identification",
            "User presence visualization"],
        [
            "Real-time collaboration",
            "Offline collaboration",
            "Human-Machine collaboration"],
        [
            "Model differencing",
            "Semantic model differencing",
            "Internal versioning",
            "External versioning",
            "Model merging",
            "Version branching",
            "Undo-redo",
            "History"],
        [
            "Locking",
            "Prevention",
            "Conflict awareness",
            "Automation of resolution",
            "Manual resolution",
            "Metrics of degree of conflict/inconsistency",
            "Eventual consistency",
            "Push notifications on conflicts"],
        [
            "P2P architecture",
            "Cloud architecture",
            "Failure recovery"]],
    'Communication' : [
        [
            "Chat",
            "Audio",
            "Voice",
            "Hand gestures",
            "Face-to-face",
            "Change review sessions",
            "Screen sharing"],
        [
            "Email",
            "Wiki",
            "Forum",
            "Proposals",
            "Voting",
            "Annotations",
            "Comments",
            "Feedback",
            "Reviews",
            "Call-For-Attention",
            "Sticky notes",
            "Tags",
            "Conflicts table",
            "Multimedia annotations",
            "Commit messages",
            "Integrated prof.-soc. networking"],
        [
            "Built-in communication tools",
            "External communication tools"]]
}

def rename(dataframe, offset, dimension, aspect):
    c = colnames[dimension][aspect]
    for i in range(0, len(c)):
        mapping = {dataframe.columns[i+offset]: c[i]}
        dataframe = dataframe.rename(columns=mapping)
    return dataframe
    
data = rename(data, 13, 'Model management', 0)
data = rename(data, 43, 'Model management', 0)
data = rename(data, 19, 'Model management', 1)
data = rename(data, 49, 'Model management', 1)
data = rename(data, 32, 'Model management', 2)
data = rename(data, 62, 'Model management', 2)
data = rename(data, 73, 'Collaboration', 0)
data = rename(data, 101, 'Collaboration', 0)
data = rename(data, 78, 'Collaboration', 1)
data = rename(data, 106, 'Collaboration', 1)
data = rename(data, 81, 'Collaboration', 2)
data = rename(data, 109, 'Collaboration', 2)
data = rename(data, 89, 'Collaboration', 3)
data = rename(data, 117, 'Collaboration', 3)
data = rename(data, 97, 'Collaboration', 4)
data = rename(data, 125, 'Collaboration', 4)
data = rename(data, 129, 'Communication', 0)
data = rename(data, 155, 'Communication', 0)
data = rename(data, 136, 'Communication', 1)
data = rename(data, 162, 'Communication', 1)
data = rename(data, 152, 'Communication', 2)
data = rename(data, 178, 'Communication', 2)

   
df = {
    'Model_management' : {
        'Models and languages' : {
            'current' : data.iloc[:, 13:19],
            'need' : data.iloc[:, 43:49],
        },
        'Model manipulation and query' : {
            'current' : data.iloc[:, 19:32],
            'need' : data.iloc[:, 49:62],
        },
        'Editors and modeling environments' : {
            'current' : data.iloc[:, 32:42],
            'need' : data.iloc[:, 62:72],
        }
    },
    'Collaboration' : {
        'Stakeholder management' : {
            'current' : data.iloc[:, 73:78],
            'need' : data.iloc[:, 101:106]
        },
        'Collaboration dynamics' : {
            'current' : data.iloc[:, 78:81],
            'need' : data.iloc[:, 106:109]
        },
        'Versioning' : {
            'current' : data.iloc[:, 81:89],
            'need' : data.iloc[:, 109:117]
        },
        'Conflicts and consistency' : {
            'current' : data.iloc[:, 89:97],
            'need' : data.iloc[:, 117:125]
        },
        'Network architecture and robustness' : {
            'current' : data.iloc[:, 97:100],
            'need' : data.iloc[:, 125:128]
        }
    },
    'Communication' : {
        'Synchronous communication' : {
            'current' : data.iloc[:, 129:136],
            'need' : data.iloc[:, 155:162],
        },
        'Asynchronous communication' : {
            'current' : data.iloc[:, 136:152],
            'need' : data.iloc[:, 162:178],
        },
        'Integration' : {
            'current' : data.iloc[:, 152:154],
            'need' : data.iloc[:, 178:180]
        }
    }
}

currentDataFrames = []
needDataFrames = []
for i in range(0, len(df)):
    subtable = df[list(df.keys())[i]]
    for j in range(0, len(list(subtable))):
        subsubtable = subtable[list(subtable.keys())[j]]
        
        current = pd.get_dummies(subsubtable['current'].stack(), dtype=int).groupby(level=1).sum()
        current = current[["I don't know.", "never", "rarely", "sometimes", "often", "always"]]
        
        current['dimension'] = list(df.keys())[i]
        current['aspect'] = list(subtable.keys())[j]
        currentDataFrames.append(current)
        
        need = pd.get_dummies(subsubtable['need'].stack(), dtype=int).groupby(level=1).sum()
        if not 'definitely not useful' in need.columns:
            need['definitely not useful'] = 0
        need = need[["I don't know.", "definitely not useful", "probably not useful", "neutral", "probably useful", "definitely useful"]]
        
        need['dimension'] = list(df.keys())[i]
        need['aspect'] = list(subtable.keys())[j]
        needDataFrames.append(need)

currentData = pd.concat(currentDataFrames)        
needData = pd.concat(needDataFrames)

currentData = currentData.reset_index(level=0)
needData = needData.reset_index(level=0)
currentData.rename(columns = {'index':'feature'}, inplace = True)
needData.rename(columns = {'index':'feature'}, inplace = True)

def calculatePercentages(row, columnsToSum):
    idk = row["I don't know."]
    support = 0
    for c in columnsToSum:
        support += row[c]
    
    support = support/(41-idk)
    return support

currentData['support'] = currentData.apply(lambda row : calculatePercentages(row, ["always", "often"]), axis=1)
currentData = currentData[['feature', 'dimension', 'aspect', 'support']]
needData['support'] = needData.apply(lambda row : calculatePercentages(row, ["definitely useful", "probably useful"]), axis=1)
needData = needData[['feature', 'dimension', 'aspect', 'support']]

mostAdopted = currentData.sort_values(by = 'support', ascending=False)[:10]
leastAdopted = (currentData.sort_values(by = 'support', ascending=True)[:10]).sort_values(by = 'support', ascending=False)
mostNeeded = needData.sort_values(by = 'support', ascending=False)[:10]
leastNeeded = (needData.sort_values(by = 'support', ascending=True)[:10]).sort_values(by = 'support', ascending=False)

def generateTable(frame):
    table = ""

    for index, row in frame.iterrows():
        #table += ("\t\t\t" + row['category'].split('[')[1].split(']')[0].strip() + "\t &\t " + row['category'].split('[')[0].strip() + "\t &\t " + str(round(row['value']*100)) + "\t \\\\ \n")
        table += ("\t\t\t" + row['feature'] + "\t &\t " + row['aspect'] + "\t &\t " + str(round(row['support']*100)) + "\t \\\\ \n")
        
    return table

with open('template/combined-template.tex', 'r') as file:
    template = file.read()
    template = template.replace('{{%%mostadopted%%}}', generateTable(mostAdopted))
    template = template.replace('{{%%leastadopted%%}}', generateTable(leastAdopted))
    template = template.replace('{{%%mostneeded%%}}', generateTable(mostNeeded))
    template = template.replace('{{%%leastneeded%%}}', generateTable(leastNeeded))

with open('{}/top-bottom-need-combined.tex'.format(outputLocation), 'w') as file:
    file.write(template)
