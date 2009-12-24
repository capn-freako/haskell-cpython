-- Copyright (C) 2009 John Millikin <jmillikin@gmail.com>
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
{-# LANGUAGE ForeignFunctionInterface #-}
module CPython.Types.Slice
	( Slice
	, sliceType
	, new
	, getIndices
	) where
import Prelude hiding (length)
import CPython.Internal hiding (new)

#include <hscpython-shim.h>

newtype Slice = Slice (ForeignPtr Slice)

instance Object Slice where
	toObject (Slice x) = SomeObject x
	fromForeignPtr = Slice

instance Concrete Slice where
	concreteType _ = sliceType

{# fun pure hscpython_PySlice_Type as sliceType
	{} -> `Type' peekStaticObject* #}

new :: (Object start, Object stop, Object step) => Maybe start -> Maybe stop -> Maybe step -> IO Slice
new start stop step =
	maybeWith withObject start $ \startPtr ->
	maybeWith withObject stop $ \stopPtr ->
	maybeWith withObject step $ \stepPtr ->
	{# call PySlice_New as ^ #} startPtr stopPtr stepPtr
	>>= stealObject

getIndices :: Slice -> Integer -> IO (Integer, Integer, Integer, Integer)
getIndices slice length =
	withObject slice $ \slicePtr ->
	let length' = fromIntegral length in
	alloca $ \startPtr ->
	alloca $ \stopPtr ->
	alloca $ \stepPtr ->
	alloca $ \sliceLenPtr -> do
	cRes <- {# call PySlice_GetIndicesEx as ^ #} slicePtr length' startPtr stopPtr stepPtr sliceLenPtr
	checkStatusCode cRes
	start <- fmap toInteger $ peek startPtr
	stop <- fmap toInteger $ peek stopPtr
	step <- fmap toInteger $ peek stepPtr
	sliceLen <- fmap toInteger $ peek sliceLenPtr
	return (start, stop, step, sliceLen)