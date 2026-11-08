import { FastifyError, FastifyReply, FastifyRequest } from 'fastify';

export function errorHandler(error: FastifyError, request: FastifyRequest, reply: FastifyReply) {
  request.log.error(error);

  const statusCode = error.statusCode || 500;
  let errorCode = 'SERVER_ERROR';

  if (statusCode === 400) errorCode = 'INVALID_INPUT';
  if (statusCode === 401) errorCode = 'AUTH_UNAUTHORIZED';
  if (statusCode === 403) errorCode = 'FORBIDDEN_RESOURCE';
  if (statusCode === 404) errorCode = 'RESOURCE_NOT_FOUND';
  if (statusCode === 409) errorCode = 'CONFLICT';
  if (statusCode === 422) errorCode = 'UNPROCESSABLE_ENTITY';
  if (statusCode === 429) errorCode = 'RATE_LIMIT_EXCEEDED';

  reply.status(statusCode).send({
    success: false,
    data: null,
    meta: {
      timestamp: new Date().toISOString(),
      correlation_id: request.id,
    },
    error: {
      code: error.code || errorCode,
      message: error.message,
      details: (error as any).validation || null,
    },
  });
}

