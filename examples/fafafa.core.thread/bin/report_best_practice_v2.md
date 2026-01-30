<html><head><meta charset='utf-8'><style>
body{font-family:Segoe UI,Arial,sans-serif;padding:16px}
table{border-collapse:collapse;margin:12px 0}
th,td{border:1px solid #ddd;padding:6px 10px;text-align:right}
th:first-child,td:first-child{text-align:left}
h1,h2,h3{margin:18px 0 8px}
code{background:#f6f8fa;padding:2px 4px;border-radius:4px}
</style></head><body>
<h1>Select Bench Report (20250817_220051)</h1>
<br/>
<div>Environment:</div>
<div>- OS: Microsoft Windows 11 专业版 10.0.26100</div>
<div>- Machine: TM1801 (12 cores, 31.8 GB RAM)</div>
<div>- CPU: Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz</div>
<br/>
<div>Input CSV(s):</div>
<div>- .\bin\matrix_full_demo.csv</div>
<br/>
<div>Meta param sets (iter,step,span,base[,tag]):</div>
<div>- 200, 7, 60, 20, tag=demo</div>
<div>- 200, 7, 100, 20, tag=demo</div>
<div>- 300, 7, 60, 20, tag=demo</div>
<div>- 300, 7, 100, 20, tag=demo</div>
<br/>
<h2>Global overview (by N)</h2>
<table>
<tr><th>N</th><th>polling avg</th><th>std</th><th>nonpolling avg</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
<tr><td>2</td><td>37.29</td><td>7.453</td><td>35.373</td><td>3.534</td><td>-1.917</td><td>-5.14</td></tr>
<tr><td>8</td><td>38.359</td><td>1.435</td><td>38.934</td><td>2.314</td><td>0.575</td><td>1.5</td></tr>
<tr><td>32</td><td>34.447</td><td>2.426</td><td>35.621</td><td>3.729</td><td>1.174</td><td>3.41</td></tr>
</table>
<br/>
<h2>Overview by tag x N</h2>
<h3>N=2</h3>
<table>
<tr><th>tag</th><th>polling avg</th><th>std</th><th>nonpolling avg</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
<tr><td>demo</td><td>37.29</td><td>7.453</td><td>35.373</td><td>3.534</td><td>-1.917</td><td>-5.14</td></tr>
</table>
<br/>
<h3>N=8</h3>
<table>
<tr><th>tag</th><th>polling avg</th><th>std</th><th>nonpolling avg</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
<tr><td>demo</td><td>38.359</td><td>1.435</td><td>38.934</td><td>2.314</td><td>0.575</td><td>1.5</td></tr>
</table>
<br/>
<h3>N=32</h3>
<table>
<tr><th>tag</th><th>polling avg</th><th>std</th><th>nonpolling avg</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
<tr><td>demo</td><td>34.447</td><td>2.426</td><td>35.621</td><td>3.729</td><td>1.174</td><td>3.41</td></tr>
</table>
<br/>
<br/>
<h2>Overview by tag (all N)</h2>
<table>
<tr><th>tag</th><th>polling avg</th><th>std</th><th>nonpolling avg</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
<tr><td>demo</td><td>36.699</td><td>4.708</td><td>36.643</td><td>3.523</td><td>-0.056</td><td>-0.15</td></tr>
</table>
<br/>
<h2>Results by parameter group</h2>
<br/>
<h3>iter=200 step=7 span=60 base=20 | tag=demo</h3>
<table>
<tr><th>N</th><th>polling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>nonpolling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
<tr><td>2</td><td>46.452</td><td>46.452</td><td>48.25</td><td>48.655</td><td>3.178</td><td>33.28</td><td>33.28</td><td>35.34</td><td>35.804</td><td>3.642</td><td>-13.172</td><td>-28.36</td></tr>
<tr><td>8</td><td>37.505</td><td>37.505</td><td>37.813</td><td>37.882</td><td>0.544</td><td>38.272</td><td>38.272</td><td>39.022</td><td>39.191</td><td>1.326</td><td>0.767</td><td>2.05</td></tr>
<tr><td>32</td><td>31.812</td><td>31.812</td><td>31.874</td><td>31.888</td><td>0.11</td><td>32.315</td><td>32.315</td><td>32.971</td><td>33.119</td><td>1.16</td><td>0.503</td><td>1.58</td></tr>
</table>
<br/>
<h3>iter=200 step=7 span=100 base=20 | tag=demo</h3>
<table>
<tr><th>N</th><th>polling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>nonpolling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
<tr><td>2</td><td>40.57</td><td>40.57</td><td>43.882</td><td>44.627</td><td>5.855</td><td>33.605</td><td>33.605</td><td>35.737</td><td>36.217</td><td>3.769</td><td>-6.965</td><td>-17.17</td></tr>
<tr><td>8</td><td>38.882</td><td>38.882</td><td>39.177</td><td>39.243</td><td>0.52</td><td>37.695</td><td>37.695</td><td>38.119</td><td>38.214</td><td>0.75</td><td>-1.187</td><td>-3.05</td></tr>
<tr><td>32</td><td>36.888</td><td>36.888</td><td>37.034</td><td>37.066</td><td>0.258</td><td>39.448</td><td>39.448</td><td>39.677</td><td>39.729</td><td>0.407</td><td>2.56</td><td>6.94</td></tr>
</table>
<br/>
<h3>iter=300 step=7 span=60 base=20 | tag=demo</h3>
<table>
<tr><th>N</th><th>polling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>nonpolling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
<tr><td>2</td><td>31.15</td><td>31.15</td><td>31.192</td><td>31.202</td><td>0.075</td><td>39.165</td><td>39.165</td><td>39.191</td><td>39.196</td><td>0.045</td><td>8.015</td><td>25.73</td></tr>
<tr><td>8</td><td>40.022</td><td>40.022</td><td>40.954</td><td>41.164</td><td>1.648</td><td>39.264</td><td>39.264</td><td>39.77</td><td>39.884</td><td>0.896</td><td>-0.758</td><td>-1.89</td></tr>
<tr><td>32</td><td>32.596</td><td>32.596</td><td>32.698</td><td>32.72</td><td>0.179</td><td>32.568</td><td>32.568</td><td>32.842</td><td>32.903</td><td>0.483</td><td>-0.028</td><td>-0.09</td></tr>
</table>
<br/>
<h3>iter=300 step=7 span=100 base=20 | tag=demo</h3>
<table>
<tr><th>N</th><th>polling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>nonpolling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
<tr><td>2</td><td>30.987</td><td>30.987</td><td>31.195</td><td>31.242</td><td>0.368</td><td>35.442</td><td>35.442</td><td>37.718</td><td>38.23</td><td>4.023</td><td>4.455</td><td>14.38</td></tr>
<tr><td>8</td><td>37.028</td><td>37.028</td><td>37.16</td><td>37.19</td><td>0.233</td><td>40.504</td><td>40.504</td><td>43.346</td><td>43.986</td><td>5.025</td><td>3.476</td><td>9.39</td></tr>
<tr><td>32</td><td>36.492</td><td>36.492</td><td>36.648</td><td>36.683</td><td>0.276</td><td>38.154</td><td>38.154</td><td>40.191</td><td>40.649</td><td>3.601</td><td>1.662</td><td>4.55</td></tr>
</table>
</body></html>
