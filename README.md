# ExpensesDB
Database for personal expenses with analytical views

<h3>Tables</h3>
<b>expenses</b><br>
The one and only table in this database that holds the source data
Tracks date, cost, category, and description of every transaction

<h3>Procedures</h3>
<b>add_month(mo varchar, y varchar)</b><br>
mo - number of the month to be added

y - year to be added

This procedure copys a csv from 'C:\tmp\' and uses the filename 'Expenses - <Month Name> <Year last 2>.csv'.

It converts the input month and year to the correct format.
  
<b>replace_month(mo varchar, y varchar)</b><br>
Essentially the same as add_month, but this procedure first deletes from the expenses table where the month and year input already exist before copying from the monthly csv file into the expenses table

<h3>Functions</h3>
<b>category_totals(y integer)</b><br>
y - year to evaluate

This function finds subtotals for each distinct category in expenses and seperates them by month, as well as totaling both monthly costs and yearly category costs.

<b>split_totals(y integer)</b><br>
like category_total but only has totals for months and not categories

<b>side_by_side_view(y integer)</b><br>
like split_totals and category_totals but without any totals

<h3>Views</h3>
<b>category_splits_2019</b><br>
calls category_totals function with the input 2019

<b>category_splits_2020</b><br>
calls category_totals function with the input 2020

<b>monthly_category_totals</b><br>
groups costs by category and month and returns a table with columns year, month, category, total

<b>monthly_totals</b><br>
groups costs by month and returns a table with columns year, month, and total
