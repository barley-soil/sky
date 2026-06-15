FROM billbear-cn-shanghai.cr.volces.com/base/billbear-node:20.15-runtime
ADD ./dist /app
WORKDIR /app
CMD ["sh", "-c", "npm install && npm run build && npm run start"]