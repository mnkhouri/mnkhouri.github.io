---
categories: projects
---
One of the clubs I am involved in needed to contact the leaders of many student organizations through a personalized form e-mail. They were sending these e-mails out one at a time, consuming a lot of manpower/time. While MS Office has a very robust mail merge feature, all of the club's documents are stored in the cloud, on Google Drive and GMail. I have found and modified a Google Apps Script for mail merge. The original version was found at http://www.labnol.org/internet/personalized-mail-merge-in-gmail/20981/. My modified version, attached to the bottom this post, allows the user to select from all available GMail "send-as" addresses, instead of only sending from the default address.

Like the original, this code is free to use and modify. To mail-merge functionality to your own documents, follow the following basic steps:
In Google Docs, create a basic spreadsheet that includes columns with each of your desired mail-merge variables (for example: e-mail address, name, position, salutation, etc...)
In your GDocs spreadsheet, go to Tools -> Script Editor and copy in the code attached to this post
In GMail, compose a draft message in which your mail-merge variables are written as $%variableName% (for example: $%name%, $%position%. Ensure that these variable names match your column names in your GDoc spreadsheet)
In your GDocs spreadsheet, go to Mail Merge -> Start Mail Merge

{% highlight javascript %}
/* 
* Mail Merge HD with GUI, Notifications and better Gmail integration
* @labnol 03/06/2012
*/

// Updated 2012/04/18 - Fixed the BCC issue
// Updated 2013/06/29 - Fixed the Sent Status issue
// Updated 2013/07/01 - Fixed the Inline Images Issue
// Updated 2013/08/15 - Fixed the UI
// Updated 2013/10/02 - Tailored this script to USAS, added email alias selection - Marc Khouri


function onOpen() {
  //create menu items in google docs
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var menu = [ 
    {name: "Clear Canvas (Reset)", functionName: "labnolReset"},
    {name: "Start Mail Merge", functionName: "fnMailMerge"}
    ];  
  ss.addMenu("Mail Merge", menu);
  ss.toast("Click the Mail Merge menu above to begin sending out auto-emails. Do this from the CLUBS TO EMAIL sheet. See instructions in the HOW TO USE sheet", "", 10);
}

function labnolReset() { 
  //reset the current canvas, except for column headers
  var mySheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();   
  mySheet.getRange(2, 1, mySheet.getMaxRows() - 1, mySheet.getMaxColumns()).clearContent();
}



/* 
* Forked from gist: 1838132 by ligthyear 
* https://gist.github.com/1907310
* Re-forked by Marc Khouri
*/

function fnMailMerge() {
  
  //find names of aliases and drafts
  var threads = GmailApp.search('in:draft', 0, 10);
  if (threads.length === 0) {
    Browser.msgBox("We found no templates in Gmail. Please save a template as a draft message in your Gmail mailbox and re-run the Mail Merge program.");
    return;
  }
  var aliases = GmailApp.getAliases();
  
  
  // build prompt and prompt for mail merge details 
  var myapp = UiApp.createApplication().setTitle('Mail Merge HD - USAS Edition').setHeight(250).setWidth(300);
  var top_panel = myapp.createFlowPanel();   
  
  top_panel.add(myapp.createLabel("Please select your Mail Merge template"));
  var lb = myapp.createListBox(false).setWidth(250).setName('templates').addItem("Select template...").setVisibleItemCount(1);
  for (var i = 0; i < threads.length; i++) {
   lb.addItem((i+1)+'- '+threads[i].getFirstMessageSubject().substr(0, 40));
  }
  top_panel.add(lb);
  top_panel.add(myapp.createLabel("").setHeight(10));
  
  top_panel.add(myapp.createLabel("Please select your outgoing e-mail"));
  var lb1 = myapp.createListBox(false).setWidth(250).setName('emailSendAddress').addItem("Send from which address?").setVisibleItemCount(1);
  for (var i = 0; i < aliases.length; i++) {
    lb1.addItem(aliases[i].substr(0, 40));
  }
  top_panel.add(lb1);  
  top_panel.add(myapp.createLabel("").setHeight(10));
  
  top_panel.add(myapp.createLabel("Please write the sender's full name"));
  var name_box = myapp.createTextBox().setName("name").setWidth(250);
  top_panel.add(name_box);  
  
  top_panel.add(myapp.createLabel("").setHeight(10));
  var bcc_box = myapp.createCheckBox().setName("bcc").setText("BCC yourself?").setWidth(250);
  top_panel.add(bcc_box); 
  
  top_panel.add(myapp.createLabel("").setHeight(5));
  var ok_btn = myapp.createButton("Start Mail Merge"); 
  top_panel.add(ok_btn);
  
  myapp.add(top_panel);
  
  
  // send data to startMailMerge function
  var handler = myapp.createServerClickHandler('startMailMerge').addCallbackElement(lb).addCallbackElement(lb1).addCallbackElement(name_box).addCallbackElement(bcc_box);
  ok_btn.addClickHandler(handler);
  
  SpreadsheetApp.getActiveSpreadsheet().show(myapp);
}



/*
* The code is written by Romain Vialard - Yet Another Mail Merge
* https://docs.google.com/document/d/1fsjHYL8TeHS2eiG217hqTgtGWI1RhRXcIvpfZFmIa3A/edit
*/

function startMailMerge(e) {
 var ss = SpreadsheetApp.getActiveSpreadsheet();
 var dataSheet = ss.getActiveSheet();
 if(dataSheet.getRange(1,dataSheet.getLastColumn()).getValue() != 'Mail Merge Status'){
   dataSheet.getRange(1,dataSheet.getLastColumn()+1).setValue('Mail Merge Status');
 }
 var headers = dataSheet.getRange(1, 1, 1, dataSheet.getLastColumn()).getValues();
 var emailColumnFound = false;
 for(i in headers[0]){
   if(headers[0][i] == "Email Address"){
     emailColumnFound = true;
   }
 }
 if(!emailColumnFound){
   var emailColumn = Browser.inputBox("Which column contains the recipient's email address ? (A, B,...)");
   dataSheet.getRange(emailColumn+''+1).setValue("Email Address");
 }
 var dataRange = dataSheet.getRange(2, 1, dataSheet.getLastRow() - 1, dataSheet.getLastColumn());

 ss.toast('Starting mail merge, please wait...','Mail Merge',-1);
  
 var selectedTemplate = GmailApp.search("in:drafts")[(parseInt(e.parameter.templates.substr(0, 2))-1)].getMessages()[0];
 var emailTemplate = selectedTemplate.getBody();
 var attachments = selectedTemplate.getAttachments();
 var cc = selectedTemplate.getCc();
 var bcc = "";
 if (e.parameter.bcc == "true") {
   bcc = selectedTemplate.getFrom();
 }
  
  var regMessageId = new RegExp(selectedTemplate.getId(), "g");
  
  if (emailTemplate.match(regMessageId) != null) {
    var inlineImages = {};
    var nbrOfImg = emailTemplate.match(regMessageId).length;
    var imgVars = emailTemplate.match(/<img[^>]+>/g);
    var imgToReplace = [];
    for (var i = 0; i < imgVars.length; i++) {
      if (imgVars[i].search(regMessageId) != -1) {
        var id = imgVars[i].match(/Inline\simages?\s(\d)/);
        imgToReplace.push([parseInt(id[1]), imgVars[i]]);
      }
    }
    imgToReplace.sort(function (a, b) {
      return a[0] - b[0];
    });
    for (var i = 0; i < imgToReplace.length; i++) {
      var attId = (attachments.length - nbrOfImg) + i;
      var title = 'inlineImages' + i;
      inlineImages[title] = attachments[attId].copyBlob().setName(title);
      attachments.splice(attId, 1);
      var newImg = imgToReplace[i][1].replace(/src="[^\"]+\"/, "src=\"cid:" + title + "\"");
      emailTemplate = emailTemplate.replace(imgToReplace[i][1], newImg);
    }
  }

  
 objects = getRowsData(dataSheet, dataRange);
 for (var i = 0; i < objects.length; ++i) {   
   var rowData = objects[i];
   if(rowData.mailMergeStatus != "EMAIL_SENT"){
     
     // Replace markers (for instance ${"First Name"}) with the 
     // corresponding value in a row object (for instance rowData.firstName).
     
     var emailText = fillInTemplateFromObject(emailTemplate, rowData);     
     var emailSubject = fillInTemplateFromObject(selectedTemplate.getSubject(), rowData);
    
     
     GmailApp.sendEmail(rowData.emailAddress, emailSubject, emailText,
                        {from: e.parameter.emailSendAddress, name: e.parameter.name, attachments: attachments, htmlBody: emailText, cc: cc, bcc: bcc, inlineImages: inlineImages});      
 
     
     dataSheet.getRange(i+2,dataSheet.getLastColumn()).setValue("EMAIL_SENT");
     
     
   }  
 }
  
  ss.toast('Shoot me feedback at MNK5084@psu.edu.','Mail Merge Complete',-1);
  //print out logger output for debug
  //ss.toast(Logger.getLog(),'Debug log',-1);
  
 var app = UiApp.getActiveApplication();
 app.close();
 return app;
}

// Replaces markers in a template string with values define in a JavaScript data object.
// Arguments:
//   - template: string containing markers, for instance ${"Column name"}
//   - data: JavaScript object with values to that will replace markers. For instance
//           data.columnName will replace marker ${"Column name"}
// Returns a string without markers. If no data is found to replace a marker, it is
// simply removed.
function fillInTemplateFromObject(template, data) {
 var email = template;
 // Search for all the variables to be replaced, for instance ${"Column name"}
 var templateVars = template.match(/\$\%[^\%]+\%/g);
 if(templateVars!= null){
   // Replace variables from the template with the actual values from the data object.
   // If no value is available, replace with the empty string.
   for (var i = 0; i < templateVars.length; ++i) {
     // normalizeHeader ignores ${"} so we can call it directly here.
     var variableData = data[normalizeHeader(templateVars[i])];
     email = email.replace(templateVars[i], variableData || "");
   }
 }
 return email;
}


/* This code is reused from the 'Reading Spreadsheet data using JavaScript Objects' tutorial */

function getRowsData(sheet, range, columnHeadersRowIndex) {
 columnHeadersRowIndex = columnHeadersRowIndex || range.getRowIndex() - 1;
 var numColumns = range.getEndColumn() - range.getColumn() + 1;
 var headersRange = sheet.getRange(columnHeadersRowIndex, range.getColumn(), 1, numColumns);
 var headers = headersRange.getValues()[0];
 return getObjects(range.getValues(), normalizeHeaders(headers));
}

function getObjects(data, keys) {
 var objects = [];
 for (var i = 0; i < data.length; ++i) {
   var object = {};
   var hasData = false;
   for (var j = 0; j < data[i].length; ++j) {
     var cellData = data[i][j];
     if (isCellEmpty(cellData)) {
       continue;
     }
     object[keys[j]] = cellData;
     hasData = true;
   }
   if (hasData) {
     objects.push(object);
   }
 }
 return objects;
}

function normalizeHeaders(headers) {
 var keys = [];
 for (var i = 0; i < headers.length; ++i) {
   var key = normalizeHeader(headers[i]);
   if (key.length > 0) {
     keys.push(key);
   }
 }
 return keys;
}

function normalizeHeader(header) {
 var key = "";
 var upperCase = false;
 for (var i = 0; i < header.length; ++i) {
   var letter = header[i];
   if (letter == " " && key.length > 0) {
     upperCase = true;
     continue;
   }
   if (!isAlnum(letter)) {
     continue;
   }
   if (key.length == 0 && isDigit(letter)) {
     continue; // first character must be a letter
   }
   if (upperCase) {
     upperCase = false;
     key += letter.toUpperCase();
   } else {
     key += letter.toLowerCase();
   }
 }
 return key;
}

function isCellEmpty(cellData) {
 return typeof(cellData) == "string" && cellData == "";
}

function isAlnum(char) {
 return char >= 'A' && char <= 'Z' ||
   char >= 'a' && char <= 'z' ||
   isDigit(char);
}

function isDigit(char) {
 return char >= '0' && char <= '9';
}
{% endhighlight %}