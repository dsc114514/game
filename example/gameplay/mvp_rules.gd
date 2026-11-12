extends RefCounted
## 用于验证闭环的 MVP 暂定规则，不代表最终平衡数值。

const MIN_PLAYERS: int = 2
const MAX_PLAYERS: int = 4
const INITIAL_MONEY: int = 0
const INITIAL_STARS: int = 0
const STAR_COST: int = 20
const COIN_REWARD: int = 10
const TARGET_STARS: int = 3
const DICE_MIN: int = 1
const DICE_MAX: int = 6

# 这里只约定格子 ID，不建立路线。中心点就是停留点，与出生点分开。
const SPAWN_TILE_ID: StringName = &"spawn"
const STOP_TILE_ID: StringName = &"center"
