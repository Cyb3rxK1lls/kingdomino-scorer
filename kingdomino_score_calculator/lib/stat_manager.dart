import 'dart:math';
import 'package:kingdomino_score_calculator/board.dart';
import 'package:kingdomino_score_calculator/disk_manager.dart';

class StatManager {
  DiskManager disker;
  StatManager(this.disker);

  final double wheatWeight = 1.0 / 26;
  final double forestWeight = 1.0 / 22;
  final double caveWeight = 1.0 / 6;
  final double graveyardWeight = 1.0 / 10;
  final double plainsWeight = 1.0 / 14;
  final double waterWeight = 1.0 / 18;

  int gamesPlayed = 0;
  int highestScore = 0;
  String favoriteRegion = "None";
  bool initialized = false;
  List<String> stats = ["Exit and reopen"];

  int totalScore = 0;
  int totalWheatScore = 0;
  int totalForestScore = 0;
  int totalCaveScore = 0;
  int totalGraveyardScore = 0;
  int totalPlainsScore = 0;
  int totalWaterScore = 0;

  double averageScore = 0;
  double averageWheatScore = 0;
  double averageForestScore = 0;
  double averageCaveScore = 0;
  double averageGraveyardScore = 0;
  double averagePlainsScore = 0;
  double averageWaterScore = 0;

  int totalWheatTiles = 0;
  int totalForestTiles = 0;
  int totalCaveTiles = 0;
  int totalGraveyardTiles = 0;
  int totalPlainsTiles = 0;
  int totalWaterTiles = 0;

  double averageWheatTiles = 0;
  double averageForestTiles = 0;
  double averageCaveTiles = 0;
  double averageGraveyardTiles = 0;
  double averagePlainsTiles = 0;
  double averageWaterTiles = 0;

  Future<void> _initialize() async {
    String stats = await disker.loadStats();
    _loadContents(stats);
    initialized = true;
  }

  void saveGame(Board game) async {
    if (!initialized) {
      await _initialize();
    }
    gamesPlayed += 1;
    totalScore += game.totalScore;
    averageScore = totalScore / gamesPlayed.toDouble();
    highestScore = max(highestScore, game.totalScore);
    Map<String, int> updates = game.getStatistics();

    totalWheatScore += updates['wheatScore']!;
    totalForestScore += updates['forestScore']!;
    totalCaveScore += updates['caveScore']!;
    totalGraveyardScore += updates['graveyardScore']!;
    totalPlainsScore += updates['plainsScore']!;
    totalWaterScore += updates['waterScore']!;

    totalWheatTiles += updates['wheatTiles']!;
    totalForestTiles += updates['forestTiles']!;
    totalCaveTiles += updates['caveTiles']!;
    totalGraveyardTiles += updates['graveyardTiles']!;
    totalPlainsTiles += updates['plainsTiles']!;
    totalWaterTiles += updates['waterTiles']!;

    averageWheatScore = totalWheatScore / gamesPlayed.toDouble();
    averageForestScore = totalForestScore / gamesPlayed.toDouble();
    averageCaveScore = totalCaveScore / gamesPlayed.toDouble();
    averageGraveyardScore = totalGraveyardScore / gamesPlayed.toDouble();
    averagePlainsScore = totalPlainsScore / gamesPlayed.toDouble();
    averageWaterScore = totalWaterScore / gamesPlayed.toDouble();

    averageWheatTiles = totalWheatTiles / gamesPlayed.toDouble();
    averageForestTiles = totalForestTiles / gamesPlayed.toDouble();
    averageCaveTiles = totalCaveTiles / gamesPlayed.toDouble();
    averageGraveyardTiles = totalGraveyardTiles / gamesPlayed.toDouble();
    averagePlainsTiles = totalPlainsTiles / gamesPlayed.toDouble();
    averageWaterTiles = totalWaterTiles / gamesPlayed.toDouble();

    favoriteRegion = "None";
    double regionValue = max(
        max(
            max(
                max(
                    max(totalWheatTiles * wheatWeight,
                        totalWaterTiles * waterWeight),
                    totalGraveyardTiles * graveyardWeight),
                totalPlainsTiles * plainsWeight),
            totalCaveTiles * caveWeight),
        totalForestTiles * forestWeight);
    if (regionValue == totalWheatTiles * wheatWeight) {
      favoriteRegion = "Wheat";
    } else if (regionValue == totalWaterTiles * waterWeight) {
      favoriteRegion = "Water";
    } else if (regionValue == totalGraveyardTiles * graveyardWeight) {
      favoriteRegion = "Graveyard";
    } else if (regionValue == totalPlainsTiles * plainsWeight) {
      favoriteRegion = "Plains";
    } else if (regionValue == totalCaveTiles * caveWeight) {
      favoriteRegion = "Cave";
    } else if (regionValue == totalForestTiles * forestWeight) {
      favoriteRegion = "Forest";
    } else {
      favoriteRegion = "None";
    }

    disker.writeStats(_packContents());
  }

  List<String> getDisplayedStats() {
    _generateStats();
    return stats;
  }

  String _packContents() {
    String output = "";
    output += "$gamesPlayed,$highestScore,$favoriteRegion,$totalScore,";
    output += "$totalWheatScore,$totalForestScore,$totalCaveScore,";
    output += "$totalGraveyardScore,$totalPlainsScore,$totalWaterScore,";
    output += "$averageScore,$averageWheatScore,$averageForestScore,";
    output += "$averageCaveScore,$averageGraveyardScore,$averagePlainsScore,";
    output += "$averageWaterScore,$totalWheatTiles,$totalForestTiles,";
    output += "$totalCaveTiles,$totalGraveyardTiles,$totalPlainsTiles,";
    output += "$totalWaterTiles,$averageWheatTiles,$averageForestTiles,";
    output += "$averageCaveTiles,$averageGraveyardTiles,$averagePlainsTiles,";
    output += "$averageWaterTiles";
    return output;
  }

  void _generateStats() async {
    if (!initialized) {
      await _initialize();
    }

    List<String> output = [];
    output.add("Games played: $gamesPlayed");
    output.add("Average score: ${averageScore.toStringAsFixed(2)}");
    output.add("Highest score: $highestScore");
    output.add("Favorite region: $favoriteRegion");
    output.add("Average wheat score: ${averageWheatScore.toStringAsFixed(2)}");
    output
        .add("Average forest score: ${averageForestScore.toStringAsFixed(2)}");
    output.add("Average cave score: ${averageCaveScore.toStringAsFixed(2)}");
    output.add(
        "Average graveyard score: ${averageGraveyardScore.toStringAsFixed(2)}");
    output
        .add("Average plains score: ${averagePlainsScore.toStringAsFixed(2)}");
    output.add("Average water score: ${averageWaterScore.toStringAsFixed(2)}");
    stats = output;
  }

  void _loadContents(String contents) {
    if (contents.isEmpty) {
      return;
    }
    List<String> variables = contents.split(',');
    gamesPlayed = int.parse(variables[0]);
    highestScore = int.parse(variables[1]);
    favoriteRegion = variables[2];
    totalScore = int.parse(variables[3]);
    totalWheatScore = int.parse(variables[4]);
    totalForestScore = int.parse(variables[5]);
    totalCaveScore = int.parse(variables[6]);
    totalGraveyardScore = int.parse(variables[7]);
    totalPlainsScore = int.parse(variables[8]);
    totalWaterScore = int.parse(variables[9]);
    averageScore = double.parse(variables[10]);
    averageWheatScore = double.parse(variables[11]);
    averageForestScore = double.parse(variables[12]);
    averageCaveScore = double.parse(variables[13]);
    averageGraveyardScore = double.parse(variables[14]);
    averagePlainsScore = double.parse(variables[15]);
    averageWaterScore = double.parse(variables[16]);
    totalWheatTiles = int.parse(variables[17]);
    totalForestTiles = int.parse(variables[18]);
    totalCaveTiles = int.parse(variables[19]);
    totalGraveyardTiles = int.parse(variables[20]);
    totalPlainsTiles = int.parse(variables[21]);
    totalWaterTiles = int.parse(variables[22]);
    averageWheatTiles = double.parse(variables[23]);
    averageForestTiles = double.parse(variables[24]);
    averageCaveTiles = double.parse(variables[25]);
    averageGraveyardTiles = double.parse(variables[26]);
    averagePlainsTiles = double.parse(variables[27]);
    averageWaterTiles = double.parse(variables[28]);
  }
}
