
class KrunEntry implements BaseKrunEntry {
  static { richards.init(); } // force class to be loaded

  public void run_iter(int param) {
      (new richards()).runIter(param);
  }
}
