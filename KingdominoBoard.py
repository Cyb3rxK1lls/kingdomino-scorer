from Tile import Tile
from random import choice


class KingdominoBoard:

    """
    An object representing the state of a Kingdomino board.

    ...

    Attributes
    ---------
    board : list[Tile]
        list of tiles that make up a board
    total_score : int
        the total score of the board
    min_x : int
        the x_mid of the leftmost tile
    max_x : int
        the x_mid of the rightmost tile
    average_width : int
        the average width of a tile
    x_dim : int
        the tile width of the board
    min_y : int
        the y_mid of the topmost tile
    max_y : int
        the y_mid of the bottommost tile
    average_height : int
        the average height of a tile
    y_dim : int
        the tile height of the board



    Methods
    -------
    get_dimensions()
        Returns the x and y dimensions, respectively
    display_tiles()
        Presents the tiles that make up the board in a grid
    display_scores()
        Presents the score of the tiles in a grid
    get_score()
        Returns total score of a board
    """

    def __init__(self, tiles):
        """
        Parameters
        ----------
        tiles : list of Tiles
            the list of tiles in a board
        """
        self.board = sorted(tiles)
        self._min_characters_in_label = 11
        self.total_score = 0

        self.min_x = min(tile.x_mid for tile in self.board)
        self.max_x = max(tile.x_mid for tile in self.board)
        self.min_y = min(tile.y_mid for tile in self.board)
        self.max_y = max(tile.y_mid for tile in self.board)

        self.average_width = 0
        self.average_height = 0
        for tile in self.board:
            self.average_width += tile.get_width()
            self.average_height += tile.get_height()
        self.average_width /= len(self.board)
        self.average_height /= len(self.board)

        self.x_dim = round((self.max_x - self.min_x) / self.average_width) + 1
        self.y_dim = round((self.max_y - self.min_y) / self.average_height) + 1
        self._handle_collisions()
        self._add_empty_tiles()
        self._calculate_score()

    def get_dimensions(self):
        """ Returns the x and y dimensions, respectively """
        return self.x_dim, self.y_dim

    def display_tiles(self):
        """ Presents the tiles that make up the board in a grid """
        output = ""
        for y in range(self.y_dim):
            for x in range(self.x_dim):
                tile = self.board[y * self.x_dim + x]
                output += self._pad_name(tile.name) + "\t"
            output += "\n"
        return output[:-1]

    def display_scores(self):
        """ Presents the score of the tiles in a grid """
        output = ""
        for y in range(self.y_dim):
            for x in range(self.x_dim):
                tile = self.board[y * self.x_dim + x]
                output += self._pad_name(tile.get_score()) + "\t"
            output += "\n"
        return output[:-1]

    def get_score(self):
        """ Returns total score of a board """
        return self.total_score

    def _get_tile(self, x_mid, y_mid):
        """
        Gets a single tile based on its coordinates on the board

        Parameters
        ----------
        x_mid : int
            the x_mid coordinate
        y_mid : int
            the y_mid coordinate
        """
        for tile in self.board:
            if tile.in_tile(Tile("empty", x_mid, y_mid, self.average_width, self.average_height)):
                return tile
        return None

    def _contains_tile(self, x_mid, y_mid):
        """
        Checks if (x, y) on a board contains a tile

        Parameters
        ----------
        x_mid : int
            the x_mid coordinate
        y_mid : int
            the y_mid coordinate
        """
        for tile in self.board:
            if tile.in_tile(Tile("empty", x_mid, y_mid, self.average_width, self.average_height)):
                return True
        return False

    def _handle_collisions(self):
        """
        Removes extra tiles if there are multiple in the same (x, y)
        location on a board. Ideally this never happens, but tests of the
        model reveal that there are misdetections where a tile is detected
        as multiple types
        """
        y = 0
        x = 0
        stop = len(self.board)
        while x < stop:
            while y < stop:
                if y == x:
                    y += 1
                    continue
                if self.board[y].in_tile(self.board[x]):
                    self.board.pop(choice([x, y]))  # remove a random one
                    stop -= 1
                y += 1
            x += 1

    def _add_empty_tiles(self):
        """ Adds an "empty" tile to any grid location in self.board that is empty """
        for y in range(self.y_dim):
            for x in range(self.x_dim):
                next_x = self.min_x + (self.average_width * x)
                next_y = self.min_y + (self.average_height * y)
                if not self._contains_tile(next_x, next_y):
                    self.board.insert(y * self.x_dim + x,
                                      Tile("empty", next_x, next_y, self.average_width, self.average_height))

    def _calculate_score(self):
        """ Calculates the score for each tile then sums it up """
        for y in range(self.y_dim):
            for x in range(self.x_dim):
                tile = self.board[y * self.x_dim + x]
                self._count_adjacent(tile)
                self.total_score += tile.get_score()

    def _count_adjacent(self, starting_tile):
        """
        Given a tile, finds all tiles of that region and populates the
        score for each of them.

        Parameters
        ----------
        starting_tile : Tile
            the starting tile of the region
        """
        # if adjacent_crowns != 0, this region's score has already been calculated and populated
        if starting_tile.adjacent_crowns == 0 and starting_tile.name != "empty":  # do not calculate empty tiles
            new_tiles = [starting_tile]
            explored = set()
            same_regions = []
            num_crowns = 0

            while new_tiles:  # continue until no new tiles to explore
                current_tile = new_tiles.pop()
                if current_tile not in explored:
                    explored.add(current_tile)
                    if current_tile.get_region() == starting_tile.get_region():  # add to score population
                        same_regions.append(current_tile)
                        num_crowns += current_tile.crowns

                        adjacent_tiles = self._get_adjacent_tiles(current_tile)
                        for tile in adjacent_tiles:
                            if tile.get_region() == starting_tile.get_region():  # more region to explore
                                new_tiles.append(tile)

            for tile in same_regions:  # populate score for each tile in the region
                tile.add_crowns(num_crowns)

    def _get_adjacent_tiles(self, tile):
        """
        Will get all legal adjacent tiles to a tile

        Parameters
        ----------
        tile : Tile
            the tile being checked
        """
        adjacent_tiles = []
        if self._contains_tile(tile.x_mid + self.average_width, tile.y_mid):
            adjacent_tiles.append(self._get_tile(tile.x_mid + self.average_width, tile.y_mid))
        if self._contains_tile(tile.x_mid - self.average_width, tile.y_mid):
            adjacent_tiles.append(self._get_tile(tile.x_mid - self.average_width, tile.y_mid))
        if self._contains_tile(tile.x_mid, tile.y_mid + self.average_height):
            adjacent_tiles.append(self._get_tile(tile.x_mid, tile.y_mid + self.average_height))
        if self._contains_tile(tile.x_mid, tile.y_mid - self.average_height):
            adjacent_tiles.append(self._get_tile(tile.x_mid, tile.y_mid - self.average_height))
        return adjacent_tiles

    def _pad_name(self, name):
        """ Pads a tile name for display purposes """
        name = str(name)
        spaces = self._min_characters_in_label - len(name)
        return (' ' * int(spaces/2)) + name + (' ' * (spaces - int(spaces/2)))