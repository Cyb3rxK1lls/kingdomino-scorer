enum Status { success, loadFailure, noDetections, nul }
enum Loading { loading, loaded, neither, nul }

class TextManager {
  String text = "";
  Status _status;
  Loading _load;

  TextManager(this._status, this._load) {
    _refreshMainText();
  }
  Loading get getLoad => _load;
  Status get getStatus => _status;
  String get getText => text;

  void _refreshMainText({String score = "", bool recentlySaved = false}) {
    if (_load == Loading.loading) {
      text = "loading...";
    } else {
      switch (_status) {
        case Status.success:
          text = "Score: " + score;
          break;

        case Status.loadFailure:
          text = "failed to load image... retry.";
          break;

        case Status.noDetections:
          if (_load == Loading.loaded) {
            text = "Found no tiles.";
          } else {
            if (recentlySaved) {
              text = "Saved! Select or take picture again";
              recentlySaved = false;
            } else {
              text = "Select or take picture";
            }
          }
          break;

        default:
      }
    }
  }

  void update(
      {Status status = Status.nul,
      Loading load = Loading.nul,
      String score = "",
      bool recentlySaved = false}) {
    if (status != Status.nul) {
      _status = status;
    }
    if (load != Loading.nul) {
      _load = load;
    }

    _refreshMainText(score: score, recentlySaved: recentlySaved);
  }
}
