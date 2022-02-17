class Tile:
    """
    A Tile object for a Kingdomino board is an individual Tile of the game.

    ...

    Attributes
    ---------
    name : str
        the name of the tile
    crowns : int
        the number of crowns on this tile
    adjacent_crowns : int
        number of crowns in the region of the tile
    x_mid : int
        the x midpoint of the tile
    x_mid : int
        the x midpoint of the tile
    x_min : int
        the x minimum of the tile
    x_max : int
        the x maximum of the tile
    y_mid : int
        the y midpoint of the tile
    y_min : int
        the y minimum of the tile
    y_max : int
        the y maximum of the tile


    Methods
    -------
    get_score()
        score of an individual tile is the number of crowns in its region
    add_crowns(amount=1)
        adds to the number of crowns in the connecting region
    in_tile(other_tile)
        checks if there is another tile inside this one
    get_region()
        returns the type of region of the tile (ignores crowns)
    get_width()
        returns the width of the tile
    get_height()
        returns the height of the tile
    """

    def __init__(self, label, x_center, y_center, tile_width, tile_height, image_size=640):
        """
        Parameters
        ----------
        label : str
            name of the tile
        x_center : float
            the x midpoint of the tile normalized to the square image_size
        y_center : float
            the y midpoint of the tile normalized to the square image_size
        tile_width : float
            the width of the tile normalized to the square image_size
        tile_height : float
            the height of the tile normalized to the square image_size
        image_size : int, default=640
            the square size of the image (i.e., width = height)
        """
        self.name = label
        self.adjacent_crowns = 0

        if label == "empty":  # initializing while building board, don't need to convert from yolov5 format
            self.x_mid = x_center
            self.y_mid = y_center
            self.crowns = 0
        else:  # initializing from *.txt file, need to convert from yolov5 format
            self.x_mid = float(x_center) * image_size
            self.y_mid = float(y_center) * image_size
            tile_width = int(float(tile_width) * image_size)
            tile_height = int(float(tile_height) * image_size)
            self.crowns = int(self.name[-1])

        self.x_max = int(self.x_mid + (tile_width / 2))
        self.x_min = int(self.x_mid - (tile_width / 2))
        self.y_min = int(self.y_mid - (tile_height / 2))
        self.y_max = int(self.y_mid + (tile_height / 2))

    def __str__(self):
        """ Overrode for printing purposes """
        return "{name} at ({xmin}, {ymin}), ({xmax}, {ymax})".format(
            name=self.name, xmin=self.x_min, xmax=self.x_max, ymin=self.y_min, ymax=self.y_max)

    def __gt__(self, other):
        """
           Tiles are ordered based on location within the grid

           Parameters
           ----------
           other: Tile
               the other tile being compared

            Raises
            ------
            TypeError
                if other is not of type Tile
           """
        if not isinstance(other, Tile):
            raise TypeError("other must be of type Tile")

        if self.y_min <= other.y_mid <= self.y_max:  # in same row => compare x values
            return self.x_mid > other.x_mid
        else:
            return self.y_mid > other.y_mid

    def __eq__(self, other):
        """
        Tiles are equal if in the same location

        Parameters
        ----------
        other: Tile
            the other tile being compared

        Raises
        ------
        TypeError
            if other is not of type Tile
        """
        if not isinstance(other, Tile):
            raise TypeError("other must be of type Tile")

        return self.in_tile(other)

    def __hash__(self):
        """ Hash of tile for list purposes """
        return hash(self.x_min) + hash(self.y_min) + hash(self.x_max) + hash(self.y_max)

    def get_score(self):
        """ Score of an individual tile is the number of crowns in its region """
        return self.adjacent_crowns

    def add_crowns(self, amount=1):
        """
        Adds to the number of crowns in the connecting region.

        Parameters
        ----------
        amount: int, optional
            The number of new crowns being added
        """
        self.adjacent_crowns += amount

    def in_tile(self, other_tile):
        """
        Boolean for the case that there is another tile in this one

        Parameters
        ----------
        other_tile : Tile
            the other tile being compared
        """
        if not isinstance(other_tile, Tile):
            raise TypeError("other_tile must be of type Tile")

        return self.x_min <= other_tile.x_mid <= self.x_max \
            and self.y_min <= other_tile.y_mid <= self.y_max

    def get_region(self):
        """ Returns the type of region of the tile (ignores crowns) """
        return self.name.split('_')[0]

    def get_width(self):
        """ Returns the width of the tile """
        return self.x_max - self.x_min

    def get_height(self):
        """ Returns the height of the tile """
        return self.y_max - self.y_min
