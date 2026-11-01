// 相容層：THSR 實作已搬到 features/railway/services/thsr/。
// 新程式請透過 RailwayProvider → RailwayRepository 取得資料，不要直接引用本檔。
import '../services/thsr/thsr_schedule_service.dart';
import '../services/thsr/thsr_train_service.dart';

@Deprecated('Use RailwayRepository.thsrTrain')
Future<dynamic> fetchHSR(String trainNo, DateTime date) =>
    const ThsrTrainService().fetchTrain(trainNo, date);

@Deprecated('Use RailwayRepository.hsrRoute')
Future<List<dynamic>> fetchHSRRoute(departureID, destinationID, time) =>
    const ThsrScheduleService()
        .fetchOdTimetable(departureID, destinationID, time);

@Deprecated('Use RailwayRepository.thsrAvailableSeatStatus')
Future<dynamic> fetchAvailableSeatStatus(
        String departureID, String arrivalID, String TrainNo, String date) =>
    const ThsrTrainService()
        .fetchAvailableSeatStatus(departureID, arrivalID, TrainNo, date);
