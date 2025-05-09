abstract interface class ParamUsecase<Param, Result> {
  Result execute(Param param);
}

abstract interface class NoParamUsecase<Result> {
  Result execute();
}
