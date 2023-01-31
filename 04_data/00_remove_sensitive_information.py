import csv

import openpyxl


def sensitive_data():
    return [(182, 4)]
    
fileLocation = '../04_data/questionnaire'
    
workbook = openpyxl.load_workbook('{}/questionnaire_data_raw.xlsx'.format(fileLocation))
sheet = workbook.active

#Remove sensitive information
for (col, colNum) in sensitive_data():
    sheet.delete_cols(col, colNum)

workbook.save(filename='{}/questionnaire_data.xlsx'.format(fileLocation))
