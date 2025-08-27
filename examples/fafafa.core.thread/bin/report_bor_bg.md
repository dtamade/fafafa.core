<html><head><meta charset='utf-8'><style>
body{font-family:Segoe UI,Arial,sans-serif;padding:16px}
table{border-collapse:collapse;margin:12px 0;max-width:100%;overflow:auto;display:block}
th,td{border:1px solid #ddd;padding:6px 10px;text-align:right}
th:first-child,td:first-child{text-align:left}
thead th{position:sticky;top:0;background:#fafafa}
tr:nth-child(even){background:#fbfbfb}
h1,h2,h3{margin:18px 0 8px}
code{background:#f6f8fa;padding:2px 4px;border-radius:4px}
a{color:#0366d6;text-decoration:none} a:hover{text-decoration:underline}
.delta-warn{color:#d97706;font-weight:600} .delta-err{color:#b91c1c;font-weight:700} .delta-ok{color:#065f46} .bg .delta-warn{background:#fff3cd} .bg .delta-err{background:#fde2e2} .bg .delta-ok{background:#e8f7f1}
</style></head><body>
<div><strong>Contents</strong><ul>
<li style='margin-left:0px'><a href='#global-overview-by-n'>Global overview (by N)</a></li>
<li style='margin-left:0px'><a href='#overview-by-tag-x-n'>Overview by tag x N</a></li>
<li style='margin-left:18px'><a href='#n2'>N=2</a></li>
<li style='margin-left:18px'><a href='#n8'>N=8</a></li>
<li style='margin-left:18px'><a href='#n32'>N=32</a></li>
<li style='margin-left:0px'><a href='#overview-by-tag-all-n'>Overview by tag (all N)</a></li>
<li style='margin-left:0px'><a href='#results-by-parameter-group'>Results by parameter group</a></li>
<li style='margin-left:18px'><a href='#iter200-step7-span60-base20-tagdemo'>iter=200 step=7 span=60 base=20 | tag=demo</a></li>
<li style='margin-left:18px'><a href='#iter200-step7-span100-base20-tagdemo'>iter=200 step=7 span=100 base=20 | tag=demo</a></li>
<li style='margin-left:18px'><a href='#iter300-step7-span60-base20-tagdemo'>iter=300 step=7 span=60 base=20 | tag=demo</a></li>
<li style='margin-left:18px'><a href='#iter300-step7-span100-base20-tagdemo'>iter=300 step=7 span=100 base=20 | tag=demo</a></li>
</ul></div><hr/>
<h1 id='select-bench-report-20250818112129'>Select Bench Report (20250818_112129)</h1>
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
<h2 id='global-overview-by-n'>Global overview (by N)</h2>
<table>
<thead>
<tr><th>N</th><th>polling avg</th><th>std</th><th>nonpolling avg</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
</thead><tbody>
<tr><td>2</td><td>37.29</td><td>7.453</td><td>35.373</td><td>3.534</td><td class='delta-warn'>-1.917</td><td class='delta-warn'>-5.14</td></tr>
<tr><td>8</td><td>38.359</td><td>1.435</td><td>38.934</td><td>2.314</td><td class='delta-ok'>0.575</td><td class='delta-ok'>1.5</td></tr>
<tr><td>32</td><td>34.447</td><td>2.426</td><td>35.621</td><td>3.729</td><td class='delta-warn'>1.174</td><td class='delta-ok'>3.41</td></tr>
</table>
<br/>
<h2 id='overview-by-tag-x-n'>Overview by tag x N</h2>
<h3 id='n2'>N=2</h3>
<table>
<thead>
<tr><th>tag</th><th>polling avg</th><th>std</th><th>nonpolling avg</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
</thead><tbody>
<tr><td>demo</td><td>37.29</td><td>7.453</td><td>35.373</td><td>3.534</td><td class='delta-warn'>-1.917</td><td class='delta-warn'>-5.14</td></tr>
</table>
<br/>
<h3 id='n8'>N=8</h3>
<table>
<thead>
<tr><th>tag</th><th>polling avg</th><th>std</th><th>nonpolling avg</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
</thead><tbody>
<tr><td>demo</td><td>38.359</td><td>1.435</td><td>38.934</td><td>2.314</td><td class='delta-ok'>0.575</td><td class='delta-ok'>1.5</td></tr>
</table>
<br/>
<h3 id='n32'>N=32</h3>
<table>
<thead>
<tr><th>tag</th><th>polling avg</th><th>std</th><th>nonpolling avg</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
</thead><tbody>
<tr><td>demo</td><td>34.447</td><td>2.426</td><td>35.621</td><td>3.729</td><td class='delta-warn'>1.174</td><td class='delta-ok'>3.41</td></tr>
</table>
<br/>
<br/>
<h2 id='overview-by-tag-all-n'>Overview by tag (all N)</h2>
<table>
<thead>
<tr><th>tag</th><th>polling avg</th><th>std</th><th>nonpolling avg</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
</thead><tbody>
<tr><td>demo</td><td>36.699</td><td>4.708</td><td>36.643</td><td>3.523</td><td class='delta-ok'>-0.056</td><td class='delta-ok'>-0.15</td></tr>
</table>
<br/>
<h2 id='results-by-parameter-group'>Results by parameter group</h2>
<br/>
<h3 id='iter200-step7-span60-base20-tagdemo'>iter=200 step=7 span=60 base=20 | tag=demo</h3>
<table>
<thead>
<tr><th>N</th><th>polling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>nonpolling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
</thead><tbody>
<tr><td>2</td><td>46.452</td><td>46.452</td><td>48.25</td><td>48.655</td><td>3.178</td><td>33.28</td><td>33.28</td><td>35.34</td><td>35.804</td><td>3.642</td><td class='delta-err'>-13.172</td><td class='delta-err'>-28.36</td></tr>
<tr><td>8</td><td>37.505</td><td>37.505</td><td>37.813</td><td>37.882</td><td>0.544</td><td>38.272</td><td>38.272</td><td>39.022</td><td>39.191</td><td>1.326</td><td class='delta-ok'>0.767</td><td class='delta-ok'>2.05</td></tr>
<tr><td>32</td><td>31.812</td><td>31.812</td><td>31.874</td><td>31.888</td><td>0.11</td><td>32.315</td><td>32.315</td><td>32.971</td><td>33.119</td><td>1.16</td><td class='delta-ok'>0.503</td><td class='delta-ok'>1.58</td></tr>
</table>
<br/>
<h3 id='iter200-step7-span100-base20-tagdemo'>iter=200 step=7 span=100 base=20 | tag=demo</h3>
<table>
<thead>
<tr><th>N</th><th>polling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>nonpolling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
</thead><tbody>
<tr><td>2</td><td>40.57</td><td>40.57</td><td>43.882</td><td>44.627</td><td>5.855</td><td>33.605</td><td>33.605</td><td>35.737</td><td>36.217</td><td>3.769</td><td class='delta-err'>-6.965</td><td class='delta-err'>-17.17</td></tr>
<tr><td>8</td><td>38.882</td><td>38.882</td><td>39.177</td><td>39.243</td><td>0.52</td><td>37.695</td><td>37.695</td><td>38.119</td><td>38.214</td><td>0.75</td><td class='delta-warn'>-1.187</td><td class='delta-ok'>-3.05</td></tr>
<tr><td>32</td><td>36.888</td><td>36.888</td><td>37.034</td><td>37.066</td><td>0.258</td><td>39.448</td><td>39.448</td><td>39.677</td><td>39.729</td><td>0.407</td><td class='delta-warn'>2.56</td><td class='delta-warn'>6.94</td></tr>
</table>
<br/>
<h3 id='iter300-step7-span60-base20-tagdemo'>iter=300 step=7 span=60 base=20 | tag=demo</h3>
<table>
<thead>
<tr><th>N</th><th>polling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>nonpolling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
</thead><tbody>
<tr><td>2</td><td>31.15</td><td>31.15</td><td>31.192</td><td>31.202</td><td>0.075</td><td>39.165</td><td>39.165</td><td>39.191</td><td>39.196</td><td>0.045</td><td class='delta-err'>8.015</td><td class='delta-err'>25.73</td></tr>
<tr><td>8</td><td>40.022</td><td>40.022</td><td>40.954</td><td>41.164</td><td>1.648</td><td>39.264</td><td>39.264</td><td>39.77</td><td>39.884</td><td>0.896</td><td class='delta-ok'>-0.758</td><td class='delta-ok'>-1.89</td></tr>
<tr><td>32</td><td>32.596</td><td>32.596</td><td>32.698</td><td>32.72</td><td>0.179</td><td>32.568</td><td>32.568</td><td>32.842</td><td>32.903</td><td>0.483</td><td class='delta-ok'>-0.028</td><td class='delta-ok'>-0.09</td></tr>
</table>
<br/>
<h3 id='iter300-step7-span100-base20-tagdemo'>iter=300 step=7 span=100 base=20 | tag=demo</h3>
<table>
<thead>
<tr><th>N</th><th>polling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>nonpolling avg</th><th>p50</th><th>p90</th><th>p99</th><th>std</th><th>delta ms</th><th>delta %</th></tr>
</thead><tbody>
<tr><td>2</td><td>30.987</td><td>30.987</td><td>31.195</td><td>31.242</td><td>0.368</td><td>35.442</td><td>35.442</td><td>37.718</td><td>38.23</td><td>4.023</td><td class='delta-err'>4.455</td><td class='delta-err'>14.38</td></tr>
<tr><td>8</td><td>37.028</td><td>37.028</td><td>37.16</td><td>37.19</td><td>0.233</td><td>40.504</td><td>40.504</td><td>43.346</td><td>43.986</td><td>5.025</td><td class='delta-err'>3.476</td><td class='delta-warn'>9.39</td></tr>
<tr><td>32</td><td>36.492</td><td>36.492</td><td>36.648</td><td>36.683</td><td>0.276</td><td>38.154</td><td>38.154</td><td>40.191</td><td>40.649</td><td>3.601</td><td class='delta-warn'>1.662</td><td class='delta-ok'>4.55</td></tr>
</table>
</body></html>
