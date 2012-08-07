module dwt.internal.mozilla.nsIPrefService;

import dwt.internal.mozilla.Common;
import dwt.internal.mozilla.nsID;
import dwt.internal.mozilla.nsISupports;
import dwt.internal.mozilla.nsIPrefBranch;
import dwt.internal.mozilla.nsIFile;

const char[] NS_IPREFSERVICE_IID_STR = "decb9cc7-c08f-4ea5-be91-a8fc637ce2d2";

const nsIID NS_IPREFSERVICE_IID=
  {0xdecb9cc7, 0xc08f, 0x4ea5,
    [ 0xbe, 0x91, 0xa8, 0xfc, 0x63, 0x7c, 0xe2, 0xd2 ]};

interface nsIPrefService : nsISupports {

  static const char[] IID_STR = NS_IPREFSERVICE_IID_STR;
  static const nsIID IID = NS_IPREFSERVICE_IID;

extern(System):
  nsresult ReadUserPrefs(nsIFile aFile);
  nsresult ResetPrefs();
  nsresult ResetUserPrefs();
  nsresult SavePrefFile(nsIFile aFile);
  nsresult GetBranch(char *aPrefRoot, nsIPrefBranch *_retval);
  nsresult GetDefaultBranch(char *aPrefRoot, nsIPrefBranch *_retval);

}

