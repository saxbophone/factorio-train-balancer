def factorio_percentage(precision: int, numerator: int, denominator: int):
    # no floating-point in Factorio, the best way to limit loss of precision is
    # to scale up before dividing
    return ((numerator * precision) // denominator)

class DropoffTrainStation:
    # the ctor params represent constants that would be hard-coded in Factorio
    # using a constant combinator
    def __init__(
        self,
        max_storeable: int,
        units_in_train_load: int,
        queue_length: int
    ):
        self.MAX_STOREABLE = max_storeable
        self.UNITS_IN_TRAIN_LOAD = units_in_train_load
        self.QUEUE_LENGTH = queue_length

    # overloaded function-call operator represents continuous input and output
    # of signals from and to the global circuit network
    def __call__(
        self,
        precision: int, # 100 for percent, 1000 for per-mille, etc...
        number_of_stations: int, # total number of stations handling this resource
        total_percentage_stored: int, # total percentage of this resource stored
        # NOTE: this is across all stations handling the resource
        units_at_this_station: int, # total amount of that resource in storage at *this* drop-off station and in stopped train
        train_count: int, # number of trains en-route to this station (includes stopped train)
        stopped_train_id: int # unique ID of stopped train, or 0 if there isn't one
    ):
        # returns:
        # percentage_stored: int, # how much of this station's storage is being used as integer percentage 0..100
        # trains_limit: int, # the recommended number of trains to send to this station, calculated from the previous inputs
        # NOTE: remember that percentage_stored also includes any train loads en-route
        trains_en_route = train_count if stopped_train_id == 0 else train_count - 1
        units_accounted = units_at_this_station + (trains_en_route * self.UNITS_IN_TRAIN_LOAD)
        # percentage_stored is also needed for trains_limit, so calculate first
        percentage_stored = self.__get_percentage_stored(
            units_accounted,
            precision
        )
        return (
            percentage_stored,
            self.__get_trains_limit(
                units_accounted,
                percentage_stored,
                total_percentage_stored,
                number_of_stations,
                train_count,
                precision
            )
        )

    def __get_percentage_stored(
        self,
        units_accounted: int,
        precision: int
    ):
        return factorio_percentage(precision, units_accounted, self.MAX_STOREABLE)

    def __get_trains_limit(
        self,
        units_accounted: int,
        percentage_stored: int,
        total_percentage_stored: int,
        number_of_stations: int,
        train_count: int,
        precision: int
    ):
        """
        Only send trains if the following conditions are true:
        - we have space left to store their payloads
        - we do not have a greater percentage_stored than the network average
        - train_count is less than queue_length
        If those conditions are true, we always send at least 1 *additional*
        train than the current train_count.
        NOTE: we used to work out how many "extra trains" we could send by
        determining how many train-loads would have to be used to make up the
        shortfall between percentage_stored and the average. However, this was
        complicated and probably unnecessary, thanks to the new idea of
        including trains en-route as part of this station's contents: with such
        a system, we can just wait for the next circuit network "tick" and then
        our station *should* have another train dispatched if one is available
        *and* we are still below the network average even when the previously
        dispatched train is taken into account.
        Also, only dispatching one additional train per tick may also more
        evenly distribute trains between equally competing stations, by not
        allowing one station to hog too many trains at once on one tick.
        """
        space_available = units_accounted < self.MAX_STOREABLE and (self.MAX_STOREABLE - units_accounted >= self.UNITS_IN_TRAIN_LOAD)
        deserves_resupply = percentage_stored <= (factorio_percentage(precision, total_percentage_stored, number_of_stations) // precision)
        space_in_the_queue = train_count < self.QUEUE_LENGTH
        return train_count + 1 if (space_available and deserves_resupply and space_in_the_queue) else train_count
