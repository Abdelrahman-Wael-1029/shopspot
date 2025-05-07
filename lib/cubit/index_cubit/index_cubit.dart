import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopspot/cubit/index_cubit/index_state.dart';

class IndexCubit extends Cubit<IndexState> {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  IndexCubit() : super(IndexInitial());

  void setIndex(int index) {
    _currentIndex = index;
    emit(IndexLoaded());
  }
}
