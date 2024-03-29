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
data = pd.read_csv('{}/demographics_data.csv'.format(dataLocation), sep=';')

outputLocation = '../06_output/demographics'
if os.path.exists(outputLocation):
    #os.rmdir(outputLocation)
    shutil.rmtree(outputLocation)
if not os.path.exists(outputLocation):
    os.makedirs(outputLocation)

#collection for non-default category thresholds
thresholds = {
    'companySize' : 0,
    'projectLength' : 0,
    'tools' : 2
}

#collection for non-default order categories
orderByCategory = ['companySize', 'modelSize', 'projectLength']

#collection for non-default pretty printed categories
prettyPrintCategory = {
    'companySize' : 'Company size',
    'projectLength' : 'Project length',
    'modelSize' : 'Model size'
}

orders = {
    'companySize' : ['1-9', '10-24', '25-49', '50-99', '100-249', '250-499', '500+'],
    'projectLength' : ['0-3', '4-12', '13-24', '25-36', '37-48', '49-60', '61+'],
    'modelSize' : ['small', 'medium', 'large']
}

titleLabelPosition = {
    'background' : 'lower right',
    'role' :  'lower right',
}

titleLabelPosition2 = {
    'projectLength' : 'lower right'
}

#def chartData(data, categories, color, fileName):
def chartData(data, settings):
    for categories, color, fileName in settings:
        
        """
        Preparation of plot data. Required for proportional layouts.
        """
        plotData = {}
        for i in range(len(categories)):
            category = categories[i]
            
            #Counter object containing a dictionary of labels and frequencies
            counter = Counter([str(val).strip() for sublist in data[category].dropna().str.split(',').tolist() for val in sublist])
            
            """
            Threshold management. Elements with a frequency below the threshold are placed into the 'Others' bin.
            """
            #Split at threshold. Default 1 is used unless specified otherwise in the #thresholds dictionary.
            threshold = thresholds[category] if category in thresholds.keys() else 1
            counterAboveTreshold = [x for x in counter.items() if x[1]>threshold]
            
            if threshold > 0: #anything not above the threshold goes into the 'Other' category
                counterUpToTreshold = [x for x in counter.items() if x[1]<=threshold]
            
            #Sort non-'Other' categories before adding the 'Other' bin.
            if category in orderByCategory:
                counterAboveTreshold = [tuple for x in orders[category] for tuple in counterAboveTreshold if tuple[0] == x]
                counterAboveTreshold.reverse()
            else:
                counterAboveTreshold = sorted(counterAboveTreshold, key=lambda x: x[1])
            
            #If there's been a meaningful threshold set AND there are elements in the 'Other' bin, append the bin.
            if threshold > 0 and len(counterUpToTreshold) > 0:
                counterAboveTreshold = [('Other', len(counterUpToTreshold))] + counterAboveTreshold

            plotData[category] = counterAboveTreshold

        numCharts = len(plotData.keys())
        rows = [len(p) for p in plotData.values()] #The height ratios of the rows are set proportionally to the rows their display.
        
        #Create subplots
        fig, axs = plt.subplots(nrows=numCharts, sharex=False, gridspec_kw={'height_ratios': rows})
        
        #If only 1 subplot, still manage it as an array for compatibility reasons.
        if len(categories) == 1:
            axs = [axs]

        """
        Plotting
        """
        for i, category in enumerate(plotData):
            counter = plotData[category]
            
            values = [element[1] for element in counter]
            sumFrequencies = sum(values)
            labels = ['{} \u2014 {} ({}%)'.format(element[0], element[1], round((element[1]/sumFrequencies)*100)) for element in counter]
            #Get the regular labels and values by: labels, values = zip(*counter)
            
            #Prepare bar chart
            indexes = np.arange(len(labels))
            width = 0.75
            
            #Create vertical bar chart
            plt.sca(axs[i])        
            plt.barh(indexes, values, width, color=color)
            plt.yticks(indexes, labels, rotation=0)

            """
            Title of the chart shown as a rotated Y axis label on the right side, inside of the plot area
            """
            title = prettyPrintCategory[category] if category in prettyPrintCategory.keys() else category.capitalize()
            axs[i].yaxis.set_label_position("right")
            plt.ylabel(title, rotation=270, fontsize=12, labelpad=-30)
            
            """
            Left here in case we'd need to revert to anchored text from right-side inner Y label
            """
            #anchored_text = AnchoredText(title, loc= titleLabelPosition[category] if category in titleLabelPosition.keys() else "center right")
            #anchored_text = AnchoredText(title, loc="center right")
            #axs[i].add_artist(anchored_text)
            
            #Remove plot area borders
            axs[i].spines['right'].set_visible(False)
            axs[i].spines['top'].set_visible(False)
            axs[i].spines['bottom'].set_visible(False)
            #Remove X ticks and labels
            plt.tick_params(axis='x', which='both', bottom=False, top=False, labelbottom=False)
            
            """
            Category label settings
            """
            #Y tick labels inside
            axs[i].tick_params(axis="y", direction="out", pad=-10)
            #no Y ticks
            axs[i].yaxis.set_ticks_position('none') 
            #align Y tick labels to the left
            ticks = axs[i].get_yticklabels()
            axs[i].set_yticklabels(ticks, ha = 'left')

            """
            Tick label font management
            """
            ax = plt.gca()
            labels=ax.get_yticklabels()+ax.get_xticklabels()
            for label in labels:
                label.set_fontsize(13)
            
            """
            Sizing and plotting
            """
            figure = plt.gcf()
            #Height proportional to the number of rows displayed
            figure.set_size_inches(8, 0.33*sum(rows))
            plt.gcf().tight_layout()

        plt.savefig('{}/{}.pdf'.format(outputLocation, fileName))
        #plt.show()  #Turn this off in final code or make it optional


chartData(data, [
    (['background', 'role'], '#85d4ff', 'person'),
    (['location', 'companySize', 'sector', 'domain'], '#ffa1c0', 'company'),
    (['tools', 'projectLength', 'modelSize'], '#ffdd47', 'model-project')]
)


def printNumericStats():
    print('Mean experience: {}.'.format(statistics.mean(data['experience'])))
    print('Std experience: {}.'.format(statistics.pstdev(data['experience'])))
    
    print('Mean collaborators: {}.'.format(statistics.mean(data['collaborators'])))
    print('Std collaborators: {}.'.format(statistics.pstdev(data['collaborators'])))
