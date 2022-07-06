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
        return (
            self.__get_percentage_stored(
                units_accounted,
                precision
            ),
            self.__get_trains_limit(
                units_accounted,
                self.__get_percentage_stored(units_at_this_station, precision),
                total_percentage_stored,
                number_of_stations,
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
        precision: int
    ):
        """
        Only send trains if the following conditions are true:
        - we have space left to store their payloads
        - we do not have a greater percentage_stored than the network average
        If those conditions are true, we calculate how much less percent stored
        we have than the average and we work out how many train-loads this
        equates to, capped to be no greater than QUEUE_LENGTH and to send no
        more trains than we have space to store the loads of.
        If this is zero, we request 1 train to be sent, otherwise we request
        the calculated number of trains to be sent.
        """
        average_percentage_stored = total_percentage_stored // number_of_stations
        if percentage_stored > average_percentage_stored:
            return 0  # send zero trains in this case
        else:
            # calculate number of trains for free space and deficit, respectively
            # free space
            free_space = self.MAX_STOREABLE - units_accounted
            trains_for_free_space = free_space // self.UNITS_IN_TRAIN_LOAD
            # percentage deficit
            percentage_deficit = average_percentage_stored - percentage_stored
            units_deficit = (percentage_deficit * self.MAX_STOREABLE) // precision
            # force trains for deficit to be at least 1
            trains_for_deficit = max(units_deficit // self.UNITS_IN_TRAIN_LOAD, 1)
            # send as many trains as the smallest of trains_for_free_space, trains_for_deficit and QUEUE_LENGTH
            return min(trains_for_free_space, trains_for_deficit, self.QUEUE_LENGTH)
