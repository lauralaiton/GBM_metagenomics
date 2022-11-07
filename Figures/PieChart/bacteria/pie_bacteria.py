import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

df = pd.read_csv('Taxonomy_table.csv')
df2 = pd.read_csv('feature-table_final.csv')

df3 = df.merge(df2, left_on='Unnamed: 0', right_on='#NAME',suffixes=('_left', '_right'))

def deletCeros(df):
	for i in range(len(df.columns)):
		df = df.loc[df[df.columns[i]] != 0, :]
	return df

def fig_pie(column,df):
	'''
	column: Class, Phylum, Order
	'''
	pie_data = df[column].value_counts()
	pie_data = pie_data.to_frame()
	pie_data = pie_data.reset_index()
	fig = px.pie(pie_data, values=pie_data.columns[1], names=pie_data.columns[0], title=column, color_discrete_sequence=px.colors.sequential.Viridis)
	fig.update_layout(uniformtext_minsize=12, uniformtext_mode='hide')
	fig.update_layout(font=dict(family="Arial, monospace",size=24))
	fig.update_layout(legend=dict(yanchor="top",y=-0.01,xanchor="left",x=0.43))
	fig.show()

def dataPie(column,df):
	pie_data = df[column].value_counts()
	pie_data = pie_data.to_frame()
	pie_data = pie_data.reset_index()
	return pie_data

df3 = deletCeros(df3)
fig_pie('Class',df3)