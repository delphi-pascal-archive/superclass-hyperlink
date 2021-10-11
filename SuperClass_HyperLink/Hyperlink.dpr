program Hyperlink;

{$R Hyperlink.res}

uses
  Windows, Messages, ShellApi;

const
  RES_DIALOG = 101;
  ID_STC_WEB = 101;
  ID_STC_MAIL = 102;
  PROP_BRUSH = 'Brush';
  PROP_NONHOVER = 'NonHover';
  PROP_YESHOVER = 'YesHover';
  LINKFONTNAME = 'Tahoma';
  LINKFONTSIZE = -10;

var
  HyperLinkHover : Boolean = FALSE;
  OldStcWndProc : Pointer;
  FontNonHover, FontYesHover : Integer;
  Brush : HBRUSH;
  EventTrack : TTrackMouseEvent;

function LinkWndProc(hLinkStc, uMsg : DWORD; wParam, lParam : Integer) : LRESULT; stdcall;
begin
  Result := 0;
  case uMsg of
    WM_MOUSELEAVE:
      if HyperLinkHover then
      begin
        HyperLinkHover := FALSE;
        FontYesHover := GetProp(hLinkStc, PROP_NONHOVER);
        if FontYesHover = 0 then
        begin
          FontYesHover := CreateFont(-MulDiv(LINKFONTSIZE, GetDeviceCaps(GetDC(hLinkStc), LOGPIXELSY), 72), 0, 0, 0,
            400, 0, 0, 0, RUSSIAN_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH,
            LINKFONTNAME);
          SetProp(hLinkStc, PROP_NONHOVER, FontYesHover);
        end;
        SendMessage(hLinkStc, WM_SETFONT, Integer(FontYesHover), Integer(TRUE));
      end;
    WM_MOUSEMOVE:
      if not HyperLinkHover then
      begin
        HyperLinkHover := TRUE;
        FontNonHover := GetProp(hLinkStc, PROP_YESHOVER);
        if FontNonHover = 0 then
        begin
          FontNonHover := CreateFont(-MulDiv(LINKFONTSIZE, GetDeviceCaps(GetDC(hLinkStc), LOGPIXELSY), 72), 0, 0, 0, 400, 0, 1, 0, RUSSIAN_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH, LINKFONTNAME);
          SetProp(hLinkStc, PROP_YESHOVER, FontNonHover);
        end;
        SendMessage(hLinkStc, WM_SETFONT, Integer(FontNonHover), Integer(TRUE));
        EventTrack.cbSize := SizeOf(EventTrack);
        EventTrack.dwFlags := TME_LEAVE;
        EventTrack.hwndTrack := hLinkStc;
        EventTrack.dwHoverTime := HOVER_DEFAULT;
        TrackMouseEvent(EventTrack);
      end;
    WM_DESTROY:
      begin
        DeleteObject(GetProp(hLinkStc, PROP_NONHOVER));
        RemoveProp(hLinkStc, PROP_NONHOVER);
        DeleteObject(GetProp(hLinkStc, PROP_YESHOVER));
        RemoveProp(hLinkStc, PROP_YESHOVER);
      end;
  else
    Result := CallWindowProc(OldStcWndProc, hLinkStc, uMsg, wParam, lParam);
  end;
end;

function MainWndProc(hWnd : HWND; uMsg : UINT; wParam, lParam : Integer) : BOOL; stdcall;
begin
  Result := TRUE;
  case uMsg of
    WM_INITDIALOG:
    begin
        FontNonHover := CreateFont(-MulDiv(LINKFONTSIZE, GetDeviceCaps(GetDC(hWnd), LOGPIXELSY), 72), 0, 0, 0, 400, 0, 0, 0, RUSSIAN_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH, LINKFONTNAME);
        SetClassLong(GetDlgItem(hWnd, ID_STC_WEB), GCL_HCURSOR, LoadCursor(0, IDC_HAND));
        SetClassLong(GetDlgItem(hWnd, ID_STC_MAIL), GCL_HCURSOR, LoadCursor(0, IDC_HAND));
        SetProp(hWnd, PROP_NONHOVER, FontNonHover);
        SendMessage(GetDlgItem(hWnd, ID_STC_WEB), WM_SETFONT, Integer(FontNonHover), Integer(TRUE));
        SendMessage(GetDlgItem(hWnd, ID_STC_MAIL), WM_SETFONT, Integer(FontNonHover), Integer(TRUE));
        OldStcWndProc := Pointer(SetWindowLong(GetDlgItem(hWnd, ID_STC_WEB), GWL_WNDPROC, Integer(@LinkWndProc)));
        OldStcWndProc := Pointer(SetWindowLong(GetDlgItem(hWnd, ID_STC_MAIL), GWL_WNDPROC, Integer(@LinkWndProc)));
    end;
    WM_CTLCOLORSTATIC:
    begin
      case GetDlgCtrlId(lParam) of
      ID_STC_WEB,ID_STC_MAIL:
        begin
          SetTextColor(DWORD(wParam), RGB(0, 0, 255));
          SetBkColor(DWORD(wParam), GetSysColor(COLOR_BTNFACE));
          Brush := GetSysColorBrush(COLOR_BTNFACE);
          SetProp(hWnd, PROP_BRUSH, Brush);
          Result := Bool(Brush);
        end
        else
          Result := Bool(DefWindowProc(hWnd, uMsg, wParam, lParam));
      end;
    end;
    WM_CLOSE:
      begin
        DeleteObject(GetProp(hWnd, PROP_BRUSH));
        RemoveProp(hWnd, PROP_BRUSH);
        DeleteObject(GetProp(hWnd, PROP_NONHOVER));
        RemoveProp(hWnd, PROP_NONHOVER);
        PostQuitMessage(0);
      end;
    WM_COMMAND:
      begin
        case LoWord(wParam) of
          ID_STC_WEB : if HyperLinkHover then ShellExecute(0, 'open', 'http://www.hyperlink.ru', nil, nil, SW_SHOWNORMAL);
          ID_STC_MAIL : if HyperLinkHover then ShellExecute(0, 'open', 'mailto:mail@hyperlink.ru', nil, nil, SW_SHOWNORMAL);
        end;
      end;
    else
      Result := FALSE;
  end;
end;

begin

  DialogBox(hInstance, MAKEINTRESOURCE(RES_DIALOG), 0, @MainWndProc);
end.

