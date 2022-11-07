import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

def deletCeros(df):
	for i in range(len(df.columns)):
		df = df.loc[df[df.columns[i]] != 0, :]
	return df

df = pd.read_csv("order.csv")
df2 = df.drop(['Grape-stage', 'Guts_per_sample', 'Sampling-date'], axis=1)
df2 = df2.transpose()

df3 = deletCeros(df2)

df3 = df3.reset_index()
df3=df3.drop(0,axis=0)

for i in range(len(df3.columns)-1):
	df3[i]=df3[i].astype(float, errors = 'raise')

df3["total"]=df3.sum(axis=1)

names = {'d__Eukaryota;p__Ascomycota;c__Sordariomycetes;o__Hypocreales':"Hypocreales",'d__Eukaryota;p__Ascomycota;c__Dothideomycetes;o__Pleosporales':"Pleosporales",'d__Eukaryota;p__Ascomycota;c__Saccharomycetes;o__Saccharomycetales':"Saccharomycetales",'d__Eukaryota;p__Ascomycota;c__Dothideomycetes;o__Capnodiales':"Capnodiales",'d__Eukaryota;p__Basidiomycota;c__Tremellomycetes;o__Tremellales':"Tremellales",'d__Eukaryota;p__Basidiomycota;c__Malasseziomycetes;o__Malasseziales':"Malasseziales",'d__Eukaryota;p__Ascomycota;c__Leotiomycetes;o__Helotiales':"Helotiales",'d__Eukaryota;p__Ascomycota;c__Eurotiomycetes;o__Eurotiales':"Eurotiales"}
df3["index"] = df3["index"].map(names)

fig = px.pie(df3, values=df3.total, names=df3["index"], title="Order", color_discrete_sequence=px.colors.sequential.Viridis)
fig.update_layout(uniformtext_minsize=12, uniformtext_mode='hide')
fig.update_layout(font=dict(family="Arial, monospace",size=24))
fig.update_layout(legend=dict(yanchor="top",y=-0.01,xanchor="left",x=0.43))
fig.show()