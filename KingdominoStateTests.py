import unittest

from KingdominoBoard import KingdominoBoard
from Tile import Tile


class TestKingdominoBoard(unittest.TestCase):

    def setUp(self):
        self.empty_tile = Tile("empty", 0.5, 0.5, 1, 1, 1)
        self.wheat_0_tile = Tile("wheat_0", 0.5, 0.5, 1, 1, 1)
        self.cave_3_tile = Tile("cave_3", 0.875, 0.875, 0.25, 0.25, 4)
        self.cave_0_tile = Tile("cave_0", 0.875, 0.625, 0.25, 0.25, 4)
        self.cave_1_tile = Tile("cave_1", 0.625, 0.625, 0.25, 0.25, 4)

    def test_multiple_region(self):
        tiles = [self.cave_3_tile, self.cave_1_tile, self.cave_0_tile]
        board = KingdominoBoard(tiles)
        self.assertEqual(12, board.get_score())
        self.assertEqual((2, 2), board.get_dimensions())
        self.assertTrue("empty" in board.display_tiles())  # also checks add_empty_tiles works

    def test_handle_collision(self):
        for i in range(0, 1000):
            tiles = [self.empty_tile, self.wheat_0_tile]
            board = KingdominoBoard(tiles)
            self.assertEqual(1, len(board.board))


class TestTile(unittest.TestCase):

    def setUp(self):
        self.empty_tile = Tile("empty", 0.5, 0.5, 1, 1, 1)
        self.wheat_0_tile = Tile("wheat_0", 0, 0, 0, 0, 0)
        self.cave_3_tile = Tile("cave_3", 0.875, 0.875, 0.25, 0.25, 4)
        self.cave_3_tile_dupe = Tile("cave_3", 0.875, 0.875, 0.25, 0.25, 4)

    def test_str(self):
        self.assertEqual(self.empty_tile.__str__(), "empty at (0, 0), (1, 1)")
        self.assertEqual(self.wheat_0_tile.__str__(), "wheat_0 at (0, 0), (0, 0)")
        self.assertEqual(self.cave_3_tile.__str__(), "cave_3 at (3, 3), (4, 4)")

    def test_order(self):
        self.assertGreater(self.cave_3_tile, self.wheat_0_tile)
        self.assertEqual(self.cave_3_tile_dupe, self.cave_3_tile)

    def test_score(self):
        self.assertEqual(0, self.cave_3_tile.get_score())
        self.cave_3_tile.add_crowns(3)
        self.assertEqual(3, self.cave_3_tile.get_score())

    def test_position(self):
        self.assertEqual((3.5, 3.5), (self.cave_3_tile.x_mid, self.cave_3_tile.y_mid))
        self.assertEqual(0, self.wheat_0_tile.get_width())
        self.assertEqual(1, self.empty_tile.get_height())

    def test_region(self):
        self.assertEqual("empty", self.empty_tile.get_region())
        self.assertEqual("wheat", self.wheat_0_tile.get_region())
        self.assertEqual("cave", self.cave_3_tile.get_region())

    def test_in_tile(self):
        self.assertFalse(self.empty_tile.in_tile(self.cave_3_tile))
        self.assertFalse(self.cave_3_tile.in_tile(self.empty_tile))
        self.assertTrue(self.empty_tile.in_tile(self.wheat_0_tile))
        self.assertFalse(self.wheat_0_tile.in_tile(self.empty_tile))


if __name__ == '__main__':
    unittest.main()
