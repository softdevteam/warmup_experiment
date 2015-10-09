
class KrunEntry implements BaseKrunEntry {
  static { nbody.init(); } // force class to be loaded

  public void run_iter(int param) {
      nbody.runIter(param);
  }
}
