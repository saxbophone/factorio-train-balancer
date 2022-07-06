from train_balancer import DropoffTrainStation


PRECISION = 1000
UNITS_IN_TRAIN_LOAD = 8_000

stations = [
    DropoffTrainStation(max_storeable=128_000, units_in_train_load=UNITS_IN_TRAIN_LOAD, queue_length=3),
    DropoffTrainStation(max_storeable=128_000, units_in_train_load=UNITS_IN_TRAIN_LOAD, queue_length=1),
    DropoffTrainStation(max_storeable=97_000, units_in_train_load=UNITS_IN_TRAIN_LOAD, queue_length=2),
    DropoffTrainStation(max_storeable=63_000, units_in_train_load=UNITS_IN_TRAIN_LOAD, queue_length=3),
    DropoffTrainStation(max_storeable=997_000, units_in_train_load=UNITS_IN_TRAIN_LOAD, queue_length=5)
]

STATION_NAMES = 'ABCDEFGHJKLMNPQRSTUVWXYZ'

STATION_COUNT = len(stations)

DISTANCES = {
    'DEPOT_TO_PICKUP_SITE': [2, 5, 3],  # there are three pickup sites
    'PICKUP_SITE_TO_STATION': [
        [1, 7, 9, 1, 1],  # and five stations to go to from them, each
        [2, 4, 2, 1, 2],
        [3, 7, 5, 3, 4],
    ],
    'STATION_TO_DEPOT': [2, 3, 7, 1, 2],
}

total_percentage_stored = 0

trains_en_route = [0] * STATION_COUNT  # NOTE: makes copies only because literal type

while True:
    new_percentage_stored = 0
    for i in range(STATION_COUNT):
        station = stations[i]
        percentage_stored, trains_limit = station(
            PRECISION,
            STATION_COUNT,
            total_percentage_stored,
            63_000,  # TODO: units_at_this_station
            trains_en_route[i],
            0  # TODO: stopped_train_id
        )
        trains_en_route[i] = trains_limit
        print('Station #{}: {}% with {} en-route'.format(i, percentage_stored / 10, trains_limit))
        new_percentage_stored += percentage_stored
    total_percentage_stored = new_percentage_stored
    input()
