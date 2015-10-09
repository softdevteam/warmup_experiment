
class KrunEntry implements BaseKrunEntry {
  static { spectralnorm.init(); } // force class to be loaded

  public void run_iter(int param) {
      spectralnorm.runIter(param);
  }
}
