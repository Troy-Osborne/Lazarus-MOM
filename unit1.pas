unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls, Menus,
  ExtCtrls, IdSimpleServer, IdTCPServer, IdCustomTCPServer, IdContext, md5;

type

  { TForm1 }

  TForm1 = class(TForm)
    ActorGrid: TStringGrid;
    ActorsLabel: TLabel;
    AutoCheck: TCheckBox;
    CheckMessagesButton: TButton;
    PopUp: TCheckBox;
    Label5: TLabel;
    Log: TMemo;
    ServerButton: TButton;
    Label4: TLabel;
    ListenQueueEdit: TEdit;
    MaxConnectionsEdit: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    TimeoutWaitEdit: TEdit;
    PortEdit: TEdit;
    IdTCPServer1: TIdTCPServer;
    MessageLabel: TLabel;
    MessageQueue: TStringGrid;
    Panel1: TPanel;
    GreenLight: TShape;
    Shadow_Cosmetic: TShape;
    ScrollBox1: TScrollBox;
    ServerLabel: TLabel;
    MainMenu: TMainMenu;
    ActorsMenu: TMenuItem;
    ActorSearchMenu: TMenuItem;
    FileMenu: TMenuItem;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem6: TMenuItem;
    ActorMessageMenu: TMenuItem;
    RedLight: TShape;
    Shadow_Cosmetic1: TShape;
    SystemMessageMenu: TMenuItem;
    Reset: TMenuItem;
    CloseMenu: TMenuItem;
    PublishMenu: TMenuItem;
    AutoCheckTimer: TTimer;
    procedure AutoCheckChange(Sender: TObject);
    procedure CheckMessagesButtonClick(Sender: TObject);
    procedure CloseMenuClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure IdTCPServer1AfterBind(Sender: TObject);
    procedure IdTCPServer1Connect(AContext: TIdContext);
    procedure IdTCPServer1Disconnect(AContext: TIdContext);
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure ScrollBox1Click(Sender: TObject);
    procedure ServerButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ActorMessageMenuClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Panel1Click(Sender: TObject);
    procedure PublishMenuClick(Sender: TObject);
    procedure AddActor(Username: string; ActorType: string; Version: string; subscribeable: Boolean;PWHASH:string);
    procedure AddMessage(Recipient: string; Sender: string; message: string);
    procedure ScrollBox1Resize(Sender: TObject);
    procedure AutoCheckTimerTimer(Sender: TObject);
    procedure GetMessagesForRecipient(RecipientID:integer);
    procedure GetMessagesForAdmin;
  private

  public

  end;

var
  Form1: TForm1;
  CurrentID: Integer;
  MessageID: Integer;
  TotalActors:Integer;
  TotalMessages:Integer;
  Connected: Boolean;
implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.PublishMenuClick(Sender: TObject);
var
  username,actortype,  password, passwordhash: string;
begin
username:=InputBox('Username','Please Enter Username','User'+IntToStr(CurrentID+1));
actortype:=InputBox('Actor Type','Actor Type','imaginary');
password:=InputBox('Password','Please Enter Your Password','Password');
passwordhash:=MD5Print(MD5String(password));
  AddActor(username,actortype,'0.00',False,passwordhash);
end;

procedure TForm1.GetMessagesForRecipient(RecipientID:integer);
var
  currentrow:integer;
  RecipientIDSTR:string;
begin
  RecipientIDSTR:=inttostr(RecipientID);
  for currentrow := 1 to MessageQueue.RowCount do begin
       if ActorGrid.Rows[currentrow][1]=RecipientIDSTR  then

  end;
  end;

procedure TForm1.GetMessagesForAdmin;
var
  currentrow:integer;
  RecipientIDSTR:string;
  sender:integer;
  message:string;
begin
  RecipientIDSTR:='0';
  if (TotalMessages>0) and (TotalActors>1) then begin
  for currentrow := 1 to TotalMessages do begin
       if MessageQueue.Rows[currentrow][1]=RecipientIDSTR  then  begin
          sender:=strtoint(MessageQueue.Rows[currentrow][2]);
          message:= MessageQueue.Rows[currentrow][5];
          if PopUp.Checked then ShowMessage('Message from '+ActorGrid.Cells[1,sender+1]+' "'+message+'";')
          else
          Log.Lines.Add('Message from '+ActorGrid.Cells[1,sender+1]+' "'+message+'";');
          //delete message once processed.
          MessageQueue.DeleteRow(currentrow);
          TotalMessages:= TotalMessages-1;
       end;
       end;
  end;
  end;


procedure TForm1.FormCreate(Sender: TObject);
var
  currentIDstring, messageIDstring: TStringList;
begin
  currentID:=1;
  //ID 0 is reserved for the Middlewear itself
  //so we set the start ID to 1
  //this number will increment every time an actor joins
  //this ensures all users have a unique numerical ID assigned to their account
  messageID:=0;
  //if file exists then load IDs from the file instead
  currentIDstring:=TStringList.Create;
  messageIDstring:=TStringList.Create;
  currentIDstring.LoadFromFile('CurrentID');
  messageIDstring.LoadFromFile('MessageID');
  currentID:=strtoint(currentIDstring.ValueFromIndex[0]);
  messageID:=strtoint(messageIDstring.ValueFromIndex[0]);
  currentIDstring.Free;
  messageIDstring.Free;
  TotalActors:=1;//The Middleware itself has an ID so 0 is reserved for messaging sysadmin (abuse will result in ban)
  TotalMessages:=0;
  //set the message ID to 0
  //this number will increment every time a new message is added to the queue
  //this ensures all messages have a unique numerical ID assigned to each communication.
  //although the messages will be removed from the middleware once sent
  //the id codes can be used indefinately by both parties as a way to reference prior messages
  Connected:=False;
  Log.Lines.LoadFromFile('Log.txt');
  Log.Lines.Add('Opened Messenger at '+DateTimeToStr(Now()));
  Log.Lines.Add('Activate Server To Begin');
  ActorGrid.LoadFromCSVFile('Actors.csv');
  TotalActors:=ActorGrid.RowCount-2;
  MessageQueue.LoadFromCSVFile('MessageQueue.csv');
  TotalMessages:=MessageQueue.RowCount-2;
end;

procedure TForm1.ServerButtonClick(Sender: TObject);
begin
  if connected=False then     begin
     GreenLight.Visible:=True;
     RedLight.Visible:=False;
     ServerButton.Caption:='Deactivate';
     IdTCPServer1.DefaultPort:=StrToInt(PortEdit.Text);
     IdTCPServer1.ListenQueue:=StrToInt(ListenQueueEdit.Text);
     IdTCPServer1.MaxConnections:=StrToInt(MaxConnectionsEdit.Text);;
     IdTCPServer1.TerminateWaitTime:=StrToInt(TimeoutWaitEdit.Text);;
     IdTCPServer1.Active:=True;
       Log.Lines.Add('Enabled TCP Server Socket at '+DateTimeToStr(Now()));
     connected:=True;
  end
  else
  begin
       RedLight.Visible:=True;
       GreenLight.Visible:=False;
       ServerButton.Caption:='Activate';
       IdTCPServer1.Active:=False;
       Log.Lines.Add('Disabled TCP Server Socket at '+DateTimeToStr(Now()));
       connected:=False;
  end;

  //If port number is valid number then set
end;

procedure TForm1.IdTCPServer1Execute(AContext: TIdContext);
begin
//Executed
end;

procedure TForm1.CloseMenuClick(Sender: TObject);
begin
  Form1.Close;
end;

procedure TForm1.AutoCheckChange(Sender: TObject);
begin
  AutoCheckTimer.Enabled:=AutoCheck.Checked;
end;

procedure TForm1.CheckMessagesButtonClick(Sender: TObject);
begin
  GetMessagesForAdmin;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  MessageIDstring,  CurrentIDstring: TStringlist; //These are for exporting the IDs as a human readable string.
begin
  MessageIDstring:= TStringlist.create;
  CurrentIDstring:= TStringlist.create;
  Log.Lines.Add('Closed Messenger At '+DateTimeToStr(Now()));
  Log.Lines.SaveToFile('Log.txt');
  ActorGrid.SaveToCSVFile('Actors.csv');
  MessageQueue.SaveToCSVFile('MessageQueue.csv');
  //on close I must export the messageID and the currentID
    MessageIDstring.Add(inttostr(MessageID));
    CurrentIDstring.Add(inttostr(CurrentID));
    MessageIDstring.SaveToFile('MessageID');
    MessageIDstring.SaveToFile('CurrentID');
  //and load that on load
  MessageIDstring.Free;
  CurrentIDstring.Free;
end;

procedure TForm1.IdTCPServer1AfterBind(Sender: TObject);
begin

end;

procedure TForm1.IdTCPServer1Connect(AContext: TIdContext);
var
  PeerIP:string;
  PeerPort:integer;
begin
   PeerIP:=AContext.Binding.PeerIP;
   PeerPort:=AContext.Binding.PeerPort;
   Log.Lines.Add('Connection established with peer '+PeerIP+':'+inttostr(PeerPort));
   AContext.Binding.Send('AuthReq;');

end;

procedure TForm1.IdTCPServer1Disconnect(AContext: TIdContext);
var
  PeerIP:string;
  PeerPort:integer;
begin
   PeerIP:=AContext.Binding.PeerIP;
   PeerPort:=AContext.Binding.PeerPort;
   Log.Lines.Add('Connection lost with peer '+PeerIP+':'+inttostr(PeerPort));

end;

procedure TForm1.ScrollBox1Click(Sender: TObject);
begin

end;

procedure TForm1.ActorMessageMenuClick(Sender: TObject);
var
  mailfrom:string;
  mailto:string;
  message:string;
begin
  mailfrom:=InputBox('Mail From','Please Enter Recipient Username','0');
  mailto:=InputBox('Mail To','Please Enter Sender Username','1');
  message:=InputBox('Mail From','Please Enter Recipient Username','This is a test message from ID 1 to ID 0');
  AddMessage(mailfrom,mailto,message);
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  ScrollBox1.Width:=Form1.Width-ScrollBox1.Left;
  ScrollBox1.Height:=Form1.Height-24;
end;

procedure TForm1.Panel1Click(Sender: TObject);
begin

end;



procedure TForm1.AddMessage(Recipient: string; Sender: string; message: string);
var
  activerow:integer;
begin
activerow:=TotalMessages+1;//The active row is one space above the current ID as the first space is reserved for the names of each column
MessageQueue.InsertRowWithValues(activerow,[inttostr(messageID),
Recipient,
Sender,
'0',
DateTimeToStr(Now()),
message]   )          ;
messageID:=messageID+1;
TotalMessages:=TotalMessages+1;


end;

procedure TForm1.ScrollBox1Resize(Sender: TObject);
begin

end;

procedure TForm1.AutoCheckTimerTimer(Sender: TObject);
begin
  GetMessagesForAdmin;
end;

procedure TForm1.AddActor(Username: string; ActorType: string; Version: string; subscribeable: Boolean;PWHASH:string);
var
  activerow:integer;
begin
Activerow:=TotalActors+1;//The active row is one space above the current ID as the first space is reserved for the names of each column
ActorGrid.InsertRowWithValues(activerow,[inttostr(currentID),
Username,
ActorType,
Version,
DateTimeToStr(Now()),
BoolToStr( subscribeable),
PWHASH] );
currentID:=currentID+1;
TotalActors:=TotalActors+1;
end;

end.

