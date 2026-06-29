
const std = @import("std");
const web = @import("web");
const Response = web.Response;
const Status = web.Status;

pub fn statusFor(err: anyerror) Status {
    return switch (err) {
        error.NotFound => .not_found,
        error.HandlerNotFound => .not_found,
        error.MissingCustomer => .unauthorized,
        error.NoContext => .internal_server_error,
        error.InvalidRequest => .bad_request,
        error.ValidationFailed => .bad_request,
        error.EmptyBody => .bad_request,
        error.UpstreamFailure => .bad_gateway,
        error.UnknownUpstream => .bad_gateway,
        error.Timeout => .gateway_timeout,
        error.CircuitOpen => .service_unavailable,
        error.BulkheadFull => .service_unavailable,
        else => .internal_server_error,
    };
}

pub fn bodyFor(err: anyerror) []const u8 {
    return switch (err) {
        error.NotFound, error.HandlerNotFound => "not found",
        error.MissingCustomer => "missing or invalid identity",
        error.InvalidRequest, error.ValidationFailed, error.EmptyBody => "bad request",
        error.UpstreamFailure, error.UnknownUpstream => "upstream error",
        error.Timeout => "upstream timeout",
        error.CircuitOpen, error.BulkheadFull => "service unavailable",
        else => "internal server error",
    };
}

pub fn respondError(res: *Response, err: anyerror) !void {
    res.status = statusFor(err);
    try res.write(bodyFor(err));
}
