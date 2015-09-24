### Introduction ###

This page explains how to used the **TreeMapGViz** in a [Google Spreadsheet](http://docs.google.com/).

### Spreadsheet Requirements ###

For the TreeMapGViz to work, the spreadsheet must have the following columns:

  * One or more **label** columns. Values must be **text**.
  * One **weights** or **sizes** column. Values must be **numeric**.
  * All label column(s) must be **to the left** of the weights column.

### Embedding the TreemMapGViz Gadget ###

  1. Select the columns or cells of the graph you want to use as input for the visualization.
  1. On the spreadsheet menu bar, choose "Insert" and then choose "Gadget...". Browse for the TreeMapGViz gadget and select it.
  1. Once the gadget appears, click "Apply" to see the result.

### Options ###

  * **Range** - the spreadsheet cells used as input for the gadget.
  * **Number** of header rows - ignores the x first rows as header rows.
  * **Layout** - determines rectangle rendering:
    * **Flat** - areas will be rendered as flat rectangle.
    * **3D** - areas are rendered with a 3D effect.
  * **Labels** - determines label rendering:
    * **Floating** - labels are resized and rendered over the corresponding rectangles.
    * **On top** - labels are shrunk and set above the corresponding rectangles.
  * **Cold Color & Hot Color** - user may provide an extra numeric column that controls rectangle colors. The minimm value will be rendered using the cold color (in standard web hexadecimal format). The maximum value will be rendered using the hot color. Values in between will be rendered as a mix.
  * **Path Token** - allows label values to be provided using a path notation (like a computer file system). The default separation token is /.